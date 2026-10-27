import Foundation

private let minPollIntervalMs = 30000
private let maxPollBackoffMs = 300_000

public enum VerifyAgeStep: String, Sendable {
    case checking, email
}

package struct VerifyAgeState: Sendable {
    package var status: KIDStatus
    package var step: VerifyAgeStep?
    package var challengeId: String?
    package var rawChallengeStatus: RawChallengeStatus?
    package var expiresAt: Date?
    package var error: KIDError?
}

@MainActor
public final class VerifyAgeController: ObservableObject {
    @Published package private(set) var state: VerifyAgeState

    private let client: any KIDClient
    private let sessionId: String
    private let civilAge: @MainActor () async throws -> Int?
    private let onSession: (@MainActor (Session) -> Void)?
    private let now: () -> Date
    private let setTimer: SetTimer
    private let clearTimer: ClearTimer
    private let log: KIDLog
    private let interval: Int
    package let tasks: TaskTracker

    private var started = false
    private var checked = false
    private var polling = false
    private var confirming = false
    private var confirmation = 0
    private var collectedEmail: String?
    private var backoff: Int
    private var timer: AnyObject?
    private var fallbackDelay = 0
    private lazy var stream = ChallengeWatch(
        client: client,
        onStatus: { [weak self] status in
            guard let self else { return false }
            let pending = await handleStatus(status)
            if pending { schedule(nil) }
            return pending
        },
        onFallback: { [weak self] in
            guard let self else { return }
            schedule(fallbackDelay)
        },
        now: now,
        log: log,
        tasks: tasks
    )

    /// - Parameters:
    ///   - civilAge: The civil age of the session's jurisdiction, which the re-read session must prove before the flow
    ///     passes.
    ///   - onSession: Receives the session re-read once k-ID reports a pass.
    package init(
        client: any KIDClient,
        sessionId: String,
        civilAge: @escaping @MainActor () async throws -> Int?,
        onSession: (@MainActor (Session) -> Void)? = nil,
        pollIntervalMs: Int? = nil,
        now: @escaping () -> Date = Date.init,
        setTimer: SetTimer? = nil,
        clearTimer: ClearTimer? = nil,
        log: KIDLog? = nil,
        tasks: TaskTracker = TaskTracker()
    ) {
        self.tasks = tasks
        self.client = client
        self.sessionId = sessionId
        self.civilAge = civilAge
        self.onSession = onSession
        self.now = now
        self.setTimer = setTimer ?? defaultSetTimer
        self.clearTimer = clearTimer ?? defaultClearTimer
        self.log = log ?? defaultLog
        interval = max(minPollIntervalMs, pollIntervalMs ?? minPollIntervalMs)
        backoff = interval
        state = VerifyAgeState(status: .running, step: .checking)
    }

    private func stopTimer() {
        if let timer {
            clearTimer(timer)
            self.timer = nil
        }
    }

    /// A nil delay arms only the deadline.
    private func schedule(_ delay: Int?) {
        guard started else { return }
        stopTimer()
        var delay = delay
        if let expiresAt = state.expiresAt {
            let remaining = Int(expiresAt.timeIntervalSince(now()) * 1000)
            if remaining <= 0 {
                finish(.fail)
                return
            }
            delay = min(delay ?? remaining, remaining)
        }
        guard let delay else { return }
        timer = setTimer({ [weak self] in self?.firePoll() }, delay)
    }

    private func watch(_ delay: Int) {
        guard started, let challengeId = state.challengeId else { return }
        fallbackDelay = delay
        schedule(stream.start(challengeId) ? nil : delay)
    }

    private func finish(_ status: KIDStatus, _ detail: Any = "") {
        if status == .error { log(.error, "age verification error \(detail)") }
        stopTimer()
        stream.stop()
        var next = state
        next.status = status
        next.step = nil
        if status == .fail { next.rawChallengeStatus = .fail }
        next.error = status == .error ? toKIDError(detail as? Error) : nil
        state = next
    }

    private func scheduleConfirm(_ delay: Int) {
        guard started else { return }
        stopTimer()
        timer = setTimer({ [weak self] in self?.fireConfirm() }, delay)
    }

    private func fireConfirm() {
        timer = nil
        tasks.spawn { [weak self] in await self?.confirmPass() }
    }

    // k-ID reporting a pass is not enough: the session itself must now prove an adult.
    // A remount can start a newer confirmation while an older read is still in flight; only the newest may land.
    private func confirmPass() async {
        confirmation += 1
        let id = confirmation
        confirming = true
        let verifiedAge: Int?
        let civil: Int?
        do {
            let read = try await client.sessionGet(sessionId, etag: nil)
            guard id == confirmation else { return }
            if let session = read.session { onSession?(session) }
            verifiedAge = read.session?.ageVerification?.verifiedAge
            civil = try await civilAge()
            guard id == confirmation else { return }
        } catch {
            guard id == confirmation else { return }
            log(.error, "could not re-read the session after verifying age; will retry \(error)")
            backoff = min(backoff * 2, maxPollBackoffMs)
            var next = state
            next.status = .error
            next.step = nil
            next.error = toKIDError(error)
            state = next
            scheduleConfirm(backoff)
            return
        }
        confirming = false
        backoff = interval
        guard let verifiedAge, let civil, verifiedAge >= civil else {
            finish(.fail)
            return
        }
        var next = state
        next.status = .pass
        next.step = nil
        next.error = nil
        next.rawChallengeStatus = state.challengeId != nil ? .pass : nil
        state = next
    }

    private func check() async {
        checked = true
        do {
            let result = try await client.sessionVerifyAge(sessionId)
            if result.status == .pass {
                await confirmPass()
                return
            }
            if result.status == .fail {
                finish(.fail)
                return
            }
            guard let challenge = result.challenge else {
                finish(.error, "challenge without an id")
                return
            }
            var next = state
            next.step = .email
            next.challengeId = challenge.challengeId
            next.rawChallengeStatus = .pending
            state = next
        } catch {
            finish(.error, error)
        }
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
            if await handleStatus(status) { schedule(stream.active ? nil : interval) }
        } catch {
            log(.error, "age verification poll failed; will retry \(error)")
            backoff = min(backoff * 2, maxPollBackoffMs)
            schedule(stream.active ? nil : backoff)
        }
    }

    private func handleStatus(_ status: ChallengeStatus) async -> Bool {
        if status.status == "PASS" {
            stopTimer()
            await confirmPass()
            stream.stop()
            return false
        }
        if status.status == "FAIL" || status.expiresAt.map({ now() > $0 }) == true {
            finish(.fail)
            return false
        }
        var next = state
        next.rawChallengeStatus = status.status == "IN_PROGRESS" ? .inProgress : .pending
        next.expiresAt = status.expiresAt
        state = next
        return true
    }

    package func startingSoon() -> Self {
        DispatchQueue.main.async { [weak self] in self?.start() }
        return self
    }

    package func start() {
        // A finished fail or error starts over with a fresh check, so remounting the view tries again.
        if state.status == .fail || (state.status == .error && !confirming) {
            stopTimer()
            started = true
            backoff = interval
            state = VerifyAgeState(status: .running, step: .checking)
            tasks.spawn { [weak self] in await self?.check() }
            return
        }
        if started { return }
        started = true
        if !checked {
            tasks.spawn { [weak self] in await self?.check() }
            return
        }
        if polling || timer != nil || stream.active { return }
        if confirming {
            scheduleConfirm(0)
        } else if state.status == .pending {
            watch(0)
        }
    }

    package func setEmail(_ email: String) {
        collectedEmail = email
    }

    @discardableResult
    package func submit() async -> KIDResult {
        guard let challengeId = state.challengeId, state.status == .running || state.status == .pending else {
            log(.warn, "submit() called before a challenge exists; nothing to send.")
            return KIDResult(ok: false, error: localKIDError())
        }
        guard let email = collectedEmail, !email.isEmpty else {
            log(.warn, "submit() called without an email; pass one to `verifyAge.submit` or render KIDSessionVerifyAge.")
            return KIDResult(ok: false, error: localKIDError())
        }
        let res = await client.challengeSendEmail(challengeId, email: email)
        guard res.ok else {
            let error = res.error ?? toKIDError(nil)
            log(.error, "could not send the verification email \(error)")
            return KIDResult(ok: false, error: error)
        }
        backoff = interval
        var next = state
        next.status = .pending
        next.step = nil
        state = next
        watch(interval)
        return KIDResult(ok: true)
    }

    package func destroy() {
        stopTimer()
        stream.stop()
        started = false
    }
}
