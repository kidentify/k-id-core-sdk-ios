import Foundation

public enum SettingsChallengeStatus: String, Sendable {
    case idle, sending, pending, error
}

public struct SettingsChallengeState: Equatable, Sendable {
    public var status: SettingsChallengeStatus
    public var permissions: [PermissionName]
    public var challengeId: String?
    /// What the challenge asks for: a grownup's approval, or the player's own age check. Nil until known.
    public var challengeKind: KIDChallengeKind?
}

package struct SettingsState: Sendable {
    package var session: Session?
    package var isLoaded: Bool
    package var error: KIDError?
    package var challenge: SettingsChallengeState
}

package struct SettingsInputs: Equatable, Sendable {
    package var sessionId: String
    package var challengeId: String?

    package init(sessionId: String, challengeId: String? = nil) {
        self.sessionId = sessionId
        self.challengeId = challengeId
    }
}

public struct KIDResult: Equatable, Sendable {
    public var ok: Bool
    public var error: KIDError?

    public static func == (lhs: KIDResult, rhs: KIDResult) -> Bool {
        guard lhs.ok == rhs.ok else { return false }
        switch (lhs.error, rhs.error) {
        case (nil, nil): return true
        case let (l?, r?):
            return l.status == r.status && l.code == r.code && l.message == r.message && l.rawCode == r.rawCode
                && l.retryAfter == r.retryAfter
        default: return false
        }
    }
}

@MainActor
public final class SettingsController: ObservableObject {
    @Published package private(set) var state: SettingsState

    private let client: any KIDClient
    private let initial: SettingsInputs
    private let onChallenge: (@MainActor (String) -> Void)?
    private let sessions: SessionStore?
    private let asks: AskWatcher
    private let ownsAsks: Bool
    private let log: KIDLog
    package let tasks: TaskTracker

    private var started = false
    private var resumed = false
    private var etag: String?
    private var sessionsSubscription: UUID?
    private var asksSubscription: UUID?
    private var attachment: UUID?
    // The ask while it is being sent, or once sending failed; after that the watcher holds it.
    private var local: SettingsChallengeState?

    /// - Parameter asks: The app-wide watcher that keeps polling an ask after this controller is destroyed; without
    ///   one, the controller polls its own asks only while started.
    package init(
        client: any KIDClient,
        initial: SettingsInputs,
        onChallenge: (@MainActor (String) -> Void)? = nil,
        sessions: SessionStore? = nil,
        asks: AskWatcher? = nil,
        pollIntervalMs: Int? = nil,
        now: @escaping () -> Date = Date.init,
        setTimer: SetTimer? = nil,
        clearTimer: ClearTimer? = nil,
        log: KIDLog? = nil
    ) {
        let tasks = TaskTracker()
        self.tasks = tasks
        self.client = client
        self.initial = initial
        self.onChallenge = onChallenge
        self.sessions = sessions
        self.log = log ?? defaultLog
        ownsAsks = asks == nil
        self.asks =
            asks
            ?? AskWatcher(
                client: client, sessions: sessions, pollIntervalMs: pollIntervalMs, now: now, setTimer: setTimer,
                clearTimer: clearTimer, log: log, tasks: tasks)
        local = initial.challengeId.map { SettingsChallengeState(status: .pending, permissions: [], challengeId: $0) }
        state = SettingsState(
            session: nil, isLoaded: false, error: nil,
            challenge: SettingsChallengeState(status: .idle, permissions: [], challengeId: nil))
        state.challenge = challengeState()
    }

    private func challengeState() -> SettingsChallengeState {
        if let local { return local }
        if let ask = asks.get(initial.sessionId) {
            return SettingsChallengeState(
                status: ask.status == .pending ? .pending : .error, permissions: ask.permissions,
                challengeId: ask.challengeId, challengeKind: ask.challengeKind)
        }
        return SettingsChallengeState(status: .idle, permissions: [], challengeId: nil)
    }

    private func syncChallenge() {
        let next = challengeState()
        if next != state.challenge { state.challenge = next }
    }

    private func setLocal(_ next: SettingsChallengeState?) {
        local = next
        syncChallenge()
    }

    private func commitSession(_ session: Session?) {
        let prev = state.session
        var next = state
        next.session = session
        next.isLoaded = true
        next.error = nil
        state = next
        if let session, session != prev { sessions?.publish(session) }
    }

    private func adoptSession(_ session: Session) {
        guard session != state.session, session.sessionId == initial.sessionId else { return }
        etag = nil
        commitSession(session)
    }

    // A restarted controller missed what was published while it was stopped.
    private func catchUpSession() {
        guard state.session != nil, let cached = sessions?.current(initial.sessionId) else { return }
        adoptSession(cached)
    }

    @discardableResult
    private func loadSession() async -> Bool {
        do {
            let read = try await client.sessionGet(initial.sessionId, etag: etag)
            if read.notModified { return true }
            guard read.session != nil else {
                state.error = read.notFound ?? toKIDError(nil)
                return true
            }
            etag = read.etag
            commitSession(read.session)
            return true
        } catch {
            log(.error, "could not load the session \(error)")
            state.error = toKIDError(error)
            return false
        }
    }

    package func startingSoon() -> Self {
        DispatchQueue.main.async { [weak self] in self?.start() }
        return self
    }

    package func start() {
        if started { return }
        started = true
        if sessionsSubscription == nil {
            sessionsSubscription = sessions?.subscribe { [weak self] in self?.adoptSession($0) }
        }
        catchUpSession()
        if asksSubscription == nil { asksSubscription = asks.subscribe { [weak self] in self?.syncChallenge() } }
        if attachment == nil {
            attachment = asks.attach(initial.sessionId) { [weak self] in await self?.loadSession() ?? true }
        }
        if ownsAsks { asks.start() }
        tasks.spawn { [weak self] in await self?.loadSession() }
        if !resumed {
            resumed = true
            if let challengeId = initial.challengeId, asks.get(initial.sessionId) == nil {
                asks.watch(initial.sessionId, challengeId: challengeId, permissions: [], delay: 0)
            }
            local = nil
        }
        syncChallenge()
    }

    @discardableResult
    package func change(_ name: PermissionName, enabled: Bool) async -> KIDResult {
        switch await client.sessionChange(initial.sessionId, name: name, enabled: enabled) {
        case .failed(let error):
            return KIDResult(ok: false, error: error)
        case .ok(let session):
            etag = nil
            commitSession(session)
            return KIDResult(ok: true)
        }
    }

    @discardableResult
    package func upgrade(_ names: [PermissionName], approverEmail: String? = nil) async -> KIDResult {
        asks.clear(initial.sessionId)
        setLocal(SettingsChallengeState(status: .sending, permissions: names, challengeId: nil))
        var challengeKind: KIDChallengeKind?
        do {
            let result = try await client.sessionUpgrade(initial.sessionId, permissionNames: names)
            guard let challenge = result.challenge else {
                await loadSession()
                setLocal(nil)
                return KIDResult(ok: true)
            }
            challengeKind = settingsChallengeKindOf(challenge.type)
            // Nothing is sent without the player's email; the next call asks again, and this challenge just expires.
            if challengeKind == .ageAssurance, approverEmail == nil {
                setLocal(
                    SettingsChallengeState(
                        status: .error, permissions: names, challengeId: nil, challengeKind: challengeKind))
                return KIDResult(
                    ok: false,
                    error: KIDError(
                        status: 0, code: .invalidRequest, message: "The player's email is needed to verify their age."))
            }
            let sent = await client.challengeSendEmail(challenge.challengeId, email: approverEmail)
            if !sent.ok {
                setLocal(
                    SettingsChallengeState(
                        status: .error, permissions: names, challengeId: challenge.challengeId,
                        challengeKind: challengeKind))
                return KIDResult(ok: false, error: sent.error ?? toKIDError(nil))
            }
            onChallenge?(challenge.challengeId)
            local = nil
            asks.watch(
                initial.sessionId, challengeId: challenge.challengeId, permissions: names, challengeKind: challengeKind)
            return KIDResult(ok: true)
        } catch {
            log(.error, "could not start the settings challenge \(error)")
            setLocal(
                SettingsChallengeState(
                    status: .error, permissions: names, challengeId: nil, challengeKind: challengeKind))
            return KIDResult(ok: false, error: toKIDError(error))
        }
    }

    package func refresh() async {
        await loadSession()
    }

    package func destroy() {
        if ownsAsks { asks.stop() }
        if let attachment { asks.detach(initial.sessionId, attachment) }
        attachment = nil
        if let asksSubscription { asks.unsubscribe(asksSubscription) }
        asksSubscription = nil
        if let sessionsSubscription { sessions?.unsubscribe(sessionsSubscription) }
        sessionsSubscription = nil
        started = false
    }
}
