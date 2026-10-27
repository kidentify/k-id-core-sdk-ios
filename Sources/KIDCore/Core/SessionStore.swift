import Foundation

/// The latest copy of each session, shared by every controller on one client, so a permission changed through
/// settings reaches the permission gate on the same session.
@MainActor
package final class SessionStore {
    private var latest: [String: Session] = [:]
    private var listeners: [UUID: (Session) -> Void] = [:]

    package init() {}

    package func publish(_ session: Session) {
        if latest[session.sessionId] == session { return }
        latest[session.sessionId] = session
        for listener in listeners.values { listener(session) }
    }

    package func current(_ sessionId: String) -> Session? {
        latest[sessionId]
    }

    package func subscribe(_ listener: @escaping (Session) -> Void) -> UUID {
        let id = UUID()
        listeners[id] = listener
        return id
    }

    package func unsubscribe(_ id: UUID) {
        listeners[id] = nil
    }
}
