import Combine
import Foundation

private let minPollIntervalMs = 30000
private let maxPollBackoffMs = 300_000
private let maxCheckAttempts = 3
private let checkRetryMs = 1000

package struct AgeGateInputs: Equatable, Sendable {
    package var jurisdiction: String?
    package var age: AgeSignal?
    package var email: String?
    package var challengeId: String?
    package var sessionId: String?

    package init(
        jurisdiction: String? = nil,
        age: AgeSignal? = nil,
        email: String? = nil,
        challengeId: String? = nil,
        sessionId: String? = nil
    ) {
        self.jurisdiction = jurisdiction
        self.age = age
        self.email = email
        self.challengeId = challengeId
        self.sessionId = sessionId
    }
}

private let consentTypeMarker = "PARENTAL_CONSENT"
// Deliberately excludes CHALLENGE_SESSION_UPGRADE_BY_AGE_ASSURANCE, which also contains "AGE_ASSURANCE".
private let assuranceTypeMarker = "AGE_GATE_AGE_ASSURANCE"

private func isConsentChallenge(_ type: String?) -> Bool {
    guard let type, !type.isEmpty else { return true }
    return type.contains(consentTypeMarker)
}

private func isAssuranceChallenge(_ type: String?) -> Bool {
    guard let type else { return false }
    return type.contains(assuranceTypeMarker)
}

/// The challenge id safe to resume from: only once its email is sent.
package func resumableChallengeId(_ state: AgeGateState) -> String? {
    state.status == .pending ? state.challengeId : nil
}

@MainActor
public final class AgeGateController: ObservableObject {
    @Published package private(set) var state: AgeGateState

    private let client: any KIDClient
    private let platformAgeSignal: (any PlatformAgeSignalProvider)?
    private let sessions: SessionStore?
    private let now: () -> Date
    private let setTimer: SetTimer
    private let clearTimer: ClearTimer
    private let log: KIDLog
    private let interval: Int
    private let initial: AgeGateInputs
    private let resuming: Bool
    package let tasks = TaskTracker()

    private var prop: (jurisdiction: String?, age: AgeSignal?, email: String?)
    private var collected: (jurisdiction: String?, age: AgeSignal?, email: String?) = (nil, nil, nil)

    private var locked: Bool
    private var lockedJurisdiction: String?
    private var lockedAge: AgeSignal?
    private var checked: Bool
    private var checking = false
    private var started = false
    private var resumeStarted = false
    private var polling = false
    private var requirementsFetched = false
    private var autoResolveFailed = false
    private var checkAttempts = 0
    private var warnedLock = false
    private var etag: String?
    private var backoff: Int
    private var timer: AnyObject?
    private var verifyAge: (sessionId: String, controller: VerifyAgeController, forward: AnyCancellable)?
    private var platformAsked = false
    private var askingPlatform = false
    private var platformSignal: PlatformAgeSignal?
    private var sessionsSubscription: UUID?
    private var fallbackDelay = 0
    private lazy var stream = ChallengeWatch(
        client: client,
        onStatus: { [weak self] status in
            guard let self else { return false }
            let pending = try await handleStatus(status)
            if pending { scheduleWithinDeadline(nil) }
            return pending
        },
        onFallback: { [weak self] in
            guard let self else { return }
            scheduleWithinDeadline(fallbackDelay)
        },
        now: now,
        log: log,
        tasks: tasks
    )

    private func challengeKindOf(_ type: String?) -> KIDChallengeKind? {
        if isConsentChallenge(type) { return .parentalConsent }
        if isAssuranceChallenge(type) { return .ageAssurance }
        return nil
    }

    package init(
        client: any KIDClient,
        initial: AgeGateInputs = AgeGateInputs(),
        platformAgeSignal: (any PlatformAgeSignalProvider)? = nil,
        sessions: SessionStore? = nil,
        pollIntervalMs: Int? = nil,
        now: @escaping () -> Date = Date.init,
        setTimer: SetTimer? = nil,
        clearTimer: ClearTimer? = nil,
        log: KIDLog? = nil
    ) {
        self.client = client
        self.platformAgeSignal = platformAgeSignal
        self.sessions = sessions
        self.now = now
        self.setTimer = setTimer ?? defaultSetTimer
        self.clearTimer = clearTimer ?? defaultClearTimer
        self.log = log ?? defaultLog
        interval = max(minPollIntervalMs, pollIntervalMs ?? minPollIntervalMs)
        backoff = interval
        self.initial = initial
        resuming = initial.challengeId != nil || initial.sessionId != nil
        prop = (initial.jurisdiction, initial.age, initial.email)
        locked = resuming
        lockedJurisdiction = initial.jurisdiction
        lockedAge = initial.age
        checked = resuming
        state = AgeGateState(
            status: initial.challengeId != nil ? .pending : .running,
            step: nil,
            challengeId: initial.challengeId,
            challengeKind: nil,
            sessionId: initial.sessionId,
            session: nil,
            claimToken: nil,
            rawChallengeStatus: initial.challengeId != nil ? .pending : nil,
            expiresAt: nil,
            requirements: nil,
            emailProvided: initial.email != nil,
            error: nil
        )
        state.step = computeStep(state)
    }

    private func effectiveJurisdiction() -> String? {
        locked ? lockedJurisdiction : (collected.jurisdiction ?? prop.jurisdiction)
    }

    private func effectiveAge() -> AgeSignal? {
        locked ? lockedAge : (prop.age ?? collected.age)
    }

    private func effectiveEmail() -> String? {
        prop.email ?? collected.email
    }

    private func jurisdictionArg() -> String? {
        guard let j = effectiveJurisdiction(), !j.isEmpty, j.lowercased() != "auto" else { return nil }
        return j
    }

    private func needJurisdiction() -> Bool {
        if jurisdictionArg() != nil { return false }
        return effectiveJurisdiction() == nil || autoResolveFailed
    }

    private func computeStep(_ state: AgeGateState) -> AgeGateStep? {
        if state.status != .running { return nil }
        if needJurisdiction() { return .jurisdiction }
        if state.challengeId != nil { return state.challengeKind == .ageAssurance ? .ageAssurance : .parentalConsent }
        // The age step waits while the platform may still supply the age instead.
        if !checked && effectiveAge() == nil && platformSignal == nil {
            return platformAgeSignal != nil && !platformAsked ? .checking : .age
        }
        return .checking
    }

    private func commit(_ patch: (inout AgeGateState) -> Void = { _ in }) {
        let prev = state.session
        var next = state
        patch(&next)
        next.step = computeStep(next)
        state = next
        syncVerifyAge()
        if let session = state.session, session != prev { sessions?.publish(session) }
    }

    private func adoptSession(_ session: Session) {
        guard session != state.session, session.sessionId == state.sessionId else { return }
        etag = nil
        commit { $0.session = session }
    }

    // A restarted gate missed what was published while it was stopped.
    private func catchUpSession() {
        guard state.session != nil, let sessionId = state.sessionId, let cached = sessions?.current(sessionId) else {
            return
        }
        adoptSession(cached)
    }

    private func syncVerifyAge() {
        guard state.status == .pass, let sessionId = state.sessionId, verifyAge?.sessionId != sessionId else { return }
        verifyAge?.controller.destroy()
        let controller = VerifyAgeController(
            client: client,
            sessionId: sessionId,
            civilAge: { [weak self] in try await self?.sessionCivilAge() },
            onSession: { [weak self] session in
                self?.etag = nil
                self?.commit { $0.session = session }
            },
            pollIntervalMs: interval,
            now: now,
            setTimer: setTimer,
            clearTimer: clearTimer,
            log: log,
            tasks: tasks
        )
        let forward = controller.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        verifyAge = (sessionId, controller, forward)
    }

    /// Verifies the player is an adult on the established session; nil until the gate passes. Nothing is sent until
    /// its `start()`.
    package func sessionVerifyAge() -> VerifyAgeController? {
        verifyAge?.controller
    }

    private func sessionCivilAge() async throws -> Int? {
        if let requirements = state.requirements { return requirements.civilAge }
        guard let jurisdiction = state.session?.jurisdiction else { return nil }
        let requirements = try await client.getRequirements(jurisdiction: jurisdiction)
        commit { $0.requirements = requirements }
        return requirements.civilAge
    }

    // A resumed session never ran the gate's requirements fetch; fetch them for its jurisdiction.
    private func fetchSessionRequirements(_ session: Session?) {
        guard state.requirements == nil, let jurisdiction = session?.jurisdiction else { return }
        tasks.spawn { [weak self] in
            guard let self else { return }
            do {
                let requirements = try await self.client.getRequirements(jurisdiction: jurisdiction)
                self.commit { $0.requirements = requirements }
            } catch {
                self.log(.error, "could not load the requirements \(error)")
            }
        }
    }

    private func stopTimer() {
        if let timer {
            clearTimer(timer)
            self.timer = nil
        }
    }

    /// A nil delay arms no poll.
    private func schedule(_ delay: Int?) {
        guard started else { return }
        stopTimer()
        guard let delay else { return }
        timer = setTimer({ [weak self] in self?.firePoll() }, delay)
    }

    private func watch(_ delay: Int) {
        guard started, let challengeId = state.challengeId else { return }
        fallbackDelay = delay
        scheduleWithinDeadline(stream.start(challengeId) ? nil : delay)
    }

    private func rearm() {
        guard !polling, timer == nil, !stream.active, state.challengeId != nil, state.status == .pending else { return }
        backoff = interval
        watch(0)
    }

    /// A nil delay arms only the deadline.
    private func scheduleWithinDeadline(_ delay: Int?) {
        var delay = delay
        if let expiresAt = state.expiresAt {
            let remaining = Int(expiresAt.timeIntervalSince(now()) * 1000)
            if remaining <= 0 {
                commit { $0.rawChallengeStatus = .fail }
                fail(.fail, "challenge expired")
                return
            }
            delay = min(delay ?? remaining, remaining)
        }
        schedule(delay)
    }

    private func maybeFetchRequirements() {
        if !started || requirementsFetched { return }
        if jurisdictionArg() == nil && (effectiveJurisdiction() == nil || autoResolveFailed) { return }
        requirementsFetched = true
        let jurisdiction = jurisdictionArg()
        tasks.spawn { [weak self] in
            guard let self else { return }
            do {
                let requirements = try await client.getRequirements(jurisdiction: jurisdiction)
                commit { $0.requirements = requirements }
                maybeAskPlatform(requirements)
                maybeCheck()
            } catch {
                if jurisdictionArg() == nil, (error as? KIDError)?.rawCode == "CANNOT_RESOLVE_JURISDICTION" {
                    autoResolveFailed = true
                    requirementsFetched = false
                    commit()
                    return
                }
                fail(.error, error)
            }
        }
    }

    private func maybeAskPlatform(_ requirements: Requirements) {
        guard let platformAgeSignal, !platformAsked else { return }
        platformAsked = true
        let gates = platformAgeGates(requirements)
        guard effectiveAge() == nil, requirements.approvedAgeCollectionMethods.contains("platform-account"), !gates.isEmpty
        else {
            commit()
            return
        }
        askingPlatform = true
        tasks.spawn { [weak self] in
            guard let self else { return }
            if await client.platformAgeSignalTrusted() {
                platformSignal = await platformAgeSignal.signal(ageGates: gates)
            }
            askingPlatform = false
            commit()
            maybeCheck()
        }
    }

    private func maybeCheck() {
        if !started || checked || checking || resuming || askingPlatform { return }
        if effectiveAge() == nil && platformSignal == nil { return }
        if state.requirements == nil { return }
        runCheck()
    }

    private func runCheck() {
        lockedJurisdiction = effectiveJurisdiction()
        lockedAge = effectiveAge()
        checking = true
        locked = true
        commit { $0.status = .running }
        let age = lockedAge
        let signal = platformSignal
        guard age != nil || signal != nil else { return }
        let jurisdiction = jurisdictionArg()
        tasks.spawn { [weak self] in await self?.check(age, signal, jurisdiction) }
    }

    private func check(_ age: AgeSignal?, _ signal: PlatformAgeSignal?, _ jurisdiction: String?) async {
        do {
            let res = try await client.ageGateCheck(age, platformAgeSignal: signal, jurisdiction: jurisdiction)
            checked = true
            checking = false
            if res.status == "PROHIBITED" {
                commit {
                    $0.status = .prohibited
                    $0.session = nil
                    $0.challengeId = nil
                }
                return
            }
            if res.status == "PASS" {
                commit {
                    $0.status = .pass
                    $0.session = res.session
                    $0.sessionId = res.session?.sessionId
                    $0.challengeId = nil
                    $0.claimToken = res.claimToken
                }
                return
            }
            // PASS_WITH_CHALLENGE is treated as CHALLENGE.
            if let challenge = res.challenge, let kind = challengeKindOf(challenge.type) {
                commit {
                    $0.status = .running
                    $0.challengeId = challenge.challengeId
                    $0.challengeKind = kind
                    $0.rawChallengeStatus = .pending
                    $0.claimToken = res.claimToken
                }
                return
            }
            fail(
                .error,
                res.challenge?.type.map { "unsupported challenge type \($0)" } ?? "challenge without an id"
            )
        } catch {
            checking = false
            let transient = (error as? KIDError).map { $0.status >= 500 } ?? true
            checkAttempts += 1
            if transient && checkAttempts < maxCheckAttempts {
                guard started else { return }
                stopTimer()
                timer = setTimer({ [weak self] in self?.runCheck() }, checkRetryMs)
                return
            }
            checked = true
            fail(.error, error)
        }
    }

    private func fail(_ status: KIDStatus, _ detail: Any) {
        if status == .error { log(.error, "age gate error \(detail)") }
        stopTimer()
        stream.stop()
        commit {
            $0.status = status
            $0.error = status == .error ? toKIDError(detail as? Error) : nil
        }
    }

    @discardableResult
    package func submit() async -> KIDResult {
        guard let challengeId = state.challengeId else {
            log(.warn, "submit() called before a challenge exists; nothing to send.")
            return KIDResult(ok: false, error: localKIDError())
        }
        guard let email = effectiveEmail(), !email.isEmpty else {
            log(.warn, "submit() called without an email; provide the `email` input or render KIDAskAnAdult / KIDVerifyAge.")
            return KIDResult(ok: false, error: localKIDError())
        }
        let res = await client.challengeSendEmail(challengeId, email: email)
        if res.ok {
            backoff = interval
            commit {
                $0.status = .pending
                $0.rawChallengeStatus = .pending
            }
            watch(interval)
            return KIDResult(ok: true)
        }
        let error = res.error ?? toKIDError(nil)
        log(.error, "could not send the challenge email \(error)")
        return KIDResult(ok: false, error: error)
    }

    private func firePoll() {
        timer = nil
        polling = true
        tasks.spawn { [weak self] in
            await self?.poll()
            self?.polling = false
        }
    }

    private func poll() async {
        guard let challengeId = state.challengeId else { return }
        do {
            let status = try await client.challengeGetStatus(challengeId)
            backoff = interval
            if try await handleStatus(status) { scheduleWithinDeadline(stream.active ? nil : interval) }
        } catch {
            log(.error, "poll failed; will retry \(error)")
            backoff = min(backoff * 2, maxPollBackoffMs)
            scheduleWithinDeadline(stream.active ? nil : backoff)
        }
    }

    private func handleStatus(_ status: ChallengeStatus) async throws -> Bool {
        if state.challengeKind == nil, let type = status._type, let kind = challengeKindOf(type) {
            commit { $0.challengeKind = kind }
        }
        if status.status == "PASS" {
            let sessionId = status.sessionId ?? state.sessionId
            var session = state.session
            if let sessionId {
                let read = try await client.sessionGet(sessionId, etag: nil)
                etag = read.etag
                session = read.session ?? session
            }
            stopTimer()
            stream.stop()
            commit {
                $0.status = .pass
                $0.rawChallengeStatus = .pass
                $0.session = session
                $0.sessionId = sessionId
            }
            fetchSessionRequirements(session)
            return false
        }
        if status.status == "FAIL" {
            commit { $0.rawChallengeStatus = .fail }
            fail(.fail, "challenge failed")
            return false
        }
        if let expiresAt = status.expiresAt, now() > expiresAt {
            commit { $0.rawChallengeStatus = .fail }
            fail(.fail, "challenge expired")
            return false
        }
        commit {
            $0.rawChallengeStatus = status.status == "IN_PROGRESS" ? .inProgress : .pending
            $0.expiresAt = status.expiresAt
        }
        return true
    }

    private func resume() {
        if let sessionId = initial.sessionId {
            tasks.spawn { [weak self] in await self?.resumeSession(sessionId) }
            return
        }
        if initial.challengeId != nil {
            backoff = interval
            watch(0)
        }
    }

    private func resumeSession(_ sessionId: String) async {
        do {
            let read = try await client.sessionGet(sessionId, etag: nil)
            etag = read.etag
            if let session = read.session {
                commit {
                    $0.status = .pass
                    $0.rawChallengeStatus = .pass
                    $0.session = session
                    $0.sessionId = sessionId
                }
                fetchSessionRequirements(session)
                return
            }
            fail(.error, "resumed session not found")
        } catch {
            fail(.error, error)
        }
    }

    package func start() {
        if started { return }
        started = true
        if sessionsSubscription == nil {
            sessionsSubscription = sessions?.subscribe { [weak self] in self?.adoptSession($0) }
        }
        catchUpSession()
        if resuming {
            if resumeStarted {
                rearm()
            } else {
                resumeStarted = true
                resume()
            }
            return
        }
        maybeFetchRequirements()
        maybeCheck()
        rearm()
    }

    package func configure(jurisdiction: String?, age: AgeSignal?, email: String?) {
        if resuming { return }
        prop.email = email
        if locked {
            let jurisdictionChanged = jurisdiction != nil && jurisdiction != lockedJurisdiction
            let ageChanged = age != nil && age != lockedAge
            if (jurisdictionChanged || ageChanged) && !warnedLock {
                warnedLock = true
                log(.warn, "age/jurisdiction ignored: an active challenge already exists for this session.")
            }
            commit { $0.emailProvided = email != nil }
            return
        }
        prop.jurisdiction = jurisdiction
        prop.age = age
        maybeFetchRequirements()
        maybeCheck()
        commit { $0.emailProvided = email != nil }
    }

    package func setJurisdiction(_ code: String) {
        if locked { return }
        collected.jurisdiction = code
        maybeFetchRequirements()
        maybeCheck()
        objectWillChange.send()
    }

    package func setAge(_ signal: AgeSignal) {
        if locked { return }
        collected.age = signal
        maybeCheck()
        objectWillChange.send()
    }

    package func setEmail(_ email: String) {
        collected.email = email
        objectWillChange.send()
    }

    package func refreshSession() async throws {
        guard let sessionId = state.sessionId else { return }
        let read: SessionRead
        do {
            read = try await client.sessionGet(sessionId, etag: etag)
        } catch let error as CancellationError {
            throw error
        } catch {
            throw toKIDError(error)
        }
        if read.notModified { return }
        etag = read.etag
        if let session = read.session { commit { $0.session = session } }
    }

    package func declarationFailed(_ error: Error?) {
        commit {
            $0.status = .error
            $0.error = toKIDError(error)
        }
    }

    package func destroy() {
        verifyAge?.controller.destroy()
        stopTimer()
        if let sessionsSubscription { sessions?.unsubscribe(sessionsSubscription) }
        sessionsSubscription = nil
        stream.stop()
        started = false
    }
}
