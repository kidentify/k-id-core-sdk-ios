import Foundation

public enum KIDStatus: String, Sendable {
    case running, pending, pass, prohibited, fail, error
}

public enum RawChallengeStatus: String, Sendable {
    case pending
    case inProgress = "in-progress"
    case pass
    case fail
}

package enum AgeGateStep: String, Sendable {
    case jurisdiction, age, parentalConsent, ageAssurance, checking
}

public enum KIDChallengeKind: String, Sendable {
    case parentalConsent, ageAssurance
}

package struct AgeGateState: Sendable {
    package var status: KIDStatus
    package var step: AgeGateStep?
    package var challengeId: String?
    package var challengeKind: KIDChallengeKind?
    package var sessionId: String?
    package var session: Session?
    /// One-time claim token for this check; nil until the check, after a
    /// prohibition, and on resume.
    package var claimToken: String?
    package var rawChallengeStatus: RawChallengeStatus?
    package var expiresAt: Date?
    package var requirements: Requirements?
    package var emailProvided: Bool
    /// Why the gate ended in `.error`: a k-ID API error as is, and any other failure as `.unavailable`.
    package var error: KIDError?
}

package typealias SetTimer = @MainActor (_ fn: @escaping @MainActor () -> Void, _ ms: Int) -> AnyObject
package typealias ClearTimer = @MainActor (_ handle: AnyObject) -> Void

final class TimerHandle {
    let task: Task<Void, Never>
    init(_ task: Task<Void, Never>) { self.task = task }
}

let defaultSetTimer: SetTimer = { fn, ms in
    TimerHandle(
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(max(0, ms)) * 1_000_000)
            if !Task.isCancelled { fn() }
        })
}

let defaultClearTimer: ClearTimer = { handle in (handle as? TimerHandle)?.task.cancel() }

package enum LogLevel { case warn, error }
package typealias KIDLog = @MainActor (LogLevel, String) -> Void

package let defaultLog: KIDLog = { level, message in
    print(level == .warn ? "[k-ID] warning: \(message)" : "[k-ID] \(message)")
}

@MainActor
package final class TaskTracker {
    private var tasks: [UUID: Task<Void, Never>] = [:]

    package init() {}

    @discardableResult
    package func spawn(_ work: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        let id = UUID()
        let task = Task { @MainActor [weak self] in
            await work()
            self?.tasks[id] = nil
        }
        tasks[id] = task
        return task
    }

    package var isIdle: Bool { tasks.isEmpty }

    package func idle() async {
        while let task = tasks.values.first {
            await task.value
        }
    }
}
