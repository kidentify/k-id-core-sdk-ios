import Foundation

private let minPollIntervalMs = 30000
private let maxPollBackoffMs = 300_000

/// A grownup ask that was emailed and is waiting on an answer; `error` once it failed or expired.
package struct PendingAsk: Equatable, Sendable {
    package enum Status: Sendable { case pending, error }
    package var status: Status
    package var challengeId: String
    package var permissions: [PermissionName]
    package var challengeKind: KIDChallengeKind?
}

/// The kind of a settings challenge, from its server type; nil while the type is unknown.
package func settingsChallengeKindOf(_ type: String?) -> KIDChallengeKind? {
    guard let type else { return nil }
    if type == "CHALLENGE_SESSION_UPGRADE_BY_AGE_ASSURANCE" { return .ageAssurance }
    if type == "CHALLENGE_SESSION_UPGRADE" || type.contains("PARENTAL_CONSENT") { return .parentalConsent }
    return nil
}

/// Watches each session's pending grownup ask until it is answered, so a grant reaches the session store whether or
/// not a settings screen is mounted.
@MainActor
package final class AskWatcher {
    private struct Polling {
        var backoff: Int
        var timer: AnyObject?
        var inFlight = false
        var granted = false
    }

    private let client: any KIDClient
    private let sessions: SessionStore?
    private let now: () -> Date
    private let setTimer: SetTimer
    private let clearTimer: ClearTimer
    private let log: KIDLog
    private let interval: Int
    package let tasks: TaskTracker

    private var started = false
    private var asks: [String: PendingAsk] = [:]
    private var polling: [String: Polling] = [:]
    private var rereads: [String: (id: UUID, reread: () async -> Bool)] = [:]
    private var listeners: [UUID: () -> Void] = [:]
    private var streams: [String: (challengeId: String, watch: ChallengeWatch)] = [:]
    private var fallbackDelays: [String: Int] = [:]

    package init(
        client: any KIDClient,
        sessions: SessionStore? = nil,
        pollIntervalMs: Int? = nil,
        now: @escaping () -> Date = Date.init,
        setTimer: SetTimer? = nil,
        clearTimer: ClearTimer? = nil,
        log: KIDLog? = nil,
        tasks: TaskTracker = TaskTracker()
    ) {
        self.client = client
        self.sessions = sessions
        self.now = now
        self.setTimer = setTimer ?? defaultSetTimer
        self.clearTimer = clearTimer ?? defaultClearTimer
        self.log = log ?? defaultLog
        self.tasks = tasks
        interval = max(minPollIntervalMs, pollIntervalMs ?? minPollIntervalMs)
    }

    package func get(_ sessionId: String) -> PendingAsk? { asks[sessionId] }

    package func subscribe(_ listener: @escaping () -> Void) -> UUID {
        let id = UUID()
        listeners[id] = listener
        return id
    }

    package func unsubscribe(_ id: UUID) {
        listeners[id] = nil
    }

    private func emit() {
        for listener in listeners.values { listener() }
    }

    /// Watches `challengeId`, replacing the session's earlier ask; without a stream it polls after `delay` ms (one
    /// poll interval by default).
    package func watch(
        _ sessionId: String, challengeId: String, permissions: [PermissionName], delay: Int? = nil,
        challengeKind: KIDChallengeKind? = nil
    ) {
        asks[sessionId] = PendingAsk(
            status: .pending, challengeId: challengeId, permissions: permissions, challengeKind: challengeKind)
        polling[sessionId, default: Polling(backoff: interval)].backoff = interval
        polling[sessionId]?.granted = false
        stopTimer(sessionId)
        emit()
        watchAsk(sessionId, delay ?? interval)
    }

    package func clear(_ sessionId: String) {
        stopTimer(sessionId)
        streams[sessionId]?.watch.stop()
        if asks.removeValue(forKey: sessionId) != nil { emit() }
    }

    /// While attached, a granted ask is re-read through `reread`, so a mounted settings screen keeps its own read.
    /// `reread` returns false when the read failed, to be retried.
    package func attach(_ sessionId: String, reread: @escaping () async -> Bool) -> UUID {
        let id = UUID()
        rereads[sessionId] = (id, reread)
        return id
    }

    package func detach(_ sessionId: String, _ id: UUID) {
        if rereads[sessionId]?.id == id { rereads[sessionId] = nil }
    }

    package func start() {
        if started { return }
        started = true
        for sessionId in asks.keys
        where polling[sessionId]?.inFlight != true && streams[sessionId]?.watch.active != true {
            watchAsk(sessionId, 0)
        }
    }

    package func stop() {
        for sessionId in polling.keys { stopTimer(sessionId) }
        for stream in streams.values { stream.watch.stop() }
        started = false
    }

    private func watchAsk(_ sessionId: String, _ delay: Int) {
        guard started, let ask = asks[sessionId], ask.status == .pending else { return }
        fallbackDelays[sessionId] = delay
        if !stream(sessionId, ask.challengeId).start(ask.challengeId) { schedule(sessionId, delay) }
    }

    private func stream(_ sessionId: String, _ challengeId: String) -> ChallengeWatch {
        if let stream = streams[sessionId] {
            streams[sessionId]?.challengeId = challengeId
            return stream.watch
        }
        let watch = ChallengeWatch(
            client: client,
            onStatus: { [weak self] status in
                guard let self, let challengeId = streams[sessionId]?.challengeId else { return false }
                return await handleStatus(sessionId, challengeId, status)
            },
            onFallback: { [weak self] in
                guard let self else { return }
                schedule(sessionId, fallbackDelays[sessionId] ?? interval)
            },
            now: now,
            log: log,
            tasks: tasks
        )
        streams[sessionId] = (challengeId, watch)
        return watch
    }

    // A poll or stream result for an ask the session has since replaced is dropped, so it never lands on the new one.
    private func isCurrent(_ sessionId: String, _ challengeId: String) -> Bool {
        asks[sessionId]?.challengeId == challengeId
    }

    private func stopTimer(_ sessionId: String) {
        if let timer = polling[sessionId]?.timer {
            clearTimer(timer)
            polling[sessionId]?.timer = nil
        }
    }

    private func schedule(_ sessionId: String, _ delay: Int) {
        guard started else { return }
        stopTimer(sessionId)
        polling[sessionId, default: Polling(backoff: interval)].timer = setTimer(
            { [weak self] in self?.firePoll(sessionId) }, delay)
    }

    private func firePoll(_ sessionId: String) {
        polling[sessionId]?.timer = nil
        polling[sessionId]?.inFlight = true
        tasks.spawn { [weak self] in
            await self?.poll(sessionId)
            self?.polling[sessionId]?.inFlight = false
        }
    }

    private func reread(_ sessionId: String) async -> Bool {
        if let attached = rereads[sessionId] { return await attached.reread() }
        do {
            if let session = try await client.sessionGet(sessionId, etag: nil).session { sessions?.publish(session) }
            return true
        } catch {
            log(.error, "could not load the session \(error)")
            return false
        }
    }

    // The grant only counts once the granted session reached the store, so a failed read is retried, not dropped.
    private func finishGranted(_ sessionId: String, _ challengeId: String) async {
        polling[sessionId]?.granted = true
        let read = await reread(sessionId)
        guard isCurrent(sessionId, challengeId) else { return }
        if !read {
            let backoff = min((polling[sessionId]?.backoff ?? interval) * 2, maxPollBackoffMs)
            polling[sessionId]?.backoff = backoff
            schedule(sessionId, backoff)
            return
        }
        polling[sessionId]?.granted = false
        asks[sessionId] = nil
        emit()
    }

    private func poll(_ sessionId: String) async {
        guard let ask = asks[sessionId], ask.status == .pending else { return }
        if polling[sessionId]?.granted == true { return await finishGranted(sessionId, ask.challengeId) }
        do {
            let status = try await client.challengeGetStatus(ask.challengeId)
            if await handleStatus(sessionId, ask.challengeId, status) { schedule(sessionId, interval) }
        } catch {
            log(.error, "could not check for the grownup's answer; will retry \(error)")
            guard isCurrent(sessionId, ask.challengeId) else { return }
            let backoff = min((polling[sessionId]?.backoff ?? interval) * 2, maxPollBackoffMs)
            polling[sessionId]?.backoff = backoff
            schedule(sessionId, backoff)
        }
    }

    private func handleStatus(_ sessionId: String, _ challengeId: String, _ status: ChallengeStatus) async -> Bool {
        guard let ask = asks[sessionId], ask.challengeId == challengeId, ask.status == .pending else { return false }
        polling[sessionId, default: Polling(backoff: interval)].backoff = interval
        if ask.permissions.isEmpty, let asked = status.permissionNames, !asked.isEmpty {
            asks[sessionId]?.permissions = asked
            emit()
        }
        if let kind = settingsChallengeKindOf(status._type), kind != ask.challengeKind {
            asks[sessionId]?.challengeKind = kind
            emit()
        }
        if status.status == "PASS" {
            await finishGranted(sessionId, challengeId)
            return false
        }
        if status.status == "FAIL" || status.expiresAt.map({ now() > $0 }) == true {
            asks[sessionId]?.status = .error
            emit()
            return false
        }
        return true
    }
}
