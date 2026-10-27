import Foundation

private let maxFailedOpens = 2
private let reconnectBaseMs = 1000
private let reconnectMaxMs = 30000
// A stream the server ends sooner than this reconnects with backoff, so a challenge the server already counts as
// expired can't spin while this device's clock still says it is live.
private let minHealthyStreamSeconds: TimeInterval = 1

/// How an opened challenge stream ended: the server closed it (with its reconnect hint, if any), or the connection
/// dropped.
package enum ChallengeStreamEnd: Equatable, Sendable {
    case closed(retryMs: Int?)
    case dropped
}

/// A server-sent events parser (the WHATWG event-stream format), fed one byte at a time.
struct SSEParser {
    struct Event: Equatable {
        var event: String
        var data: String
    }

    /// The server's last `retry:` hint, in ms.
    private(set) var retryMs: Int?
    private var line: [UInt8] = []
    private var lastWasCR = false
    private var event = ""
    private var data: [String] = []

    /// Returns the event a blank line completes.
    mutating func push(_ byte: UInt8) -> Event? {
        let isLF = byte == UInt8(ascii: "\n")
        let isCR = byte == UInt8(ascii: "\r")
        defer { lastWasCR = isCR }
        if isLF && lastWasCR { return nil }
        guard isLF || isCR else {
            line.append(byte)
            return nil
        }
        defer { line.removeAll(keepingCapacity: true) }
        return process(String(decoding: line, as: UTF8.self))
    }

    private mutating func process(_ text: String) -> Event? {
        if text.isEmpty {
            defer {
                event = ""
                data = []
            }
            return data.isEmpty ? nil : Event(event: event.isEmpty ? "message" : event, data: data.joined(separator: "\n"))
        }
        if text.hasPrefix(":") { return nil }
        let field: Substring
        var value: Substring
        if let colon = text.firstIndex(of: ":") {
            field = text[..<colon]
            value = text[text.index(after: colon)...]
            if value.hasPrefix(" ") { value = value.dropFirst() }
        } else {
            field = Substring(text)
            value = ""
        }
        switch field {
        case "event": event = String(value)
        case "data": data.append(String(value))
        case "retry": if !value.isEmpty, value.allSatisfy(\.isASCII), let ms = Int(value) { retryMs = ms }
        default: break
        }
        return nil
    }
}

/// Watches a challenge's status over the server's event stream, reconnecting as needed, and falls back to polling
/// when streaming is unavailable (404) or fails to open twice in a row.
@MainActor
final class ChallengeWatch {
    private let client: any KIDClient
    /// Handles one status; returns false once the challenge needs no more watching.
    private let onStatus: @MainActor (ChallengeStatus) async throws -> Bool
    /// Streaming is unavailable for this challenge, so the caller polls it instead.
    private let onFallback: @MainActor () -> Void
    private let now: () -> Date
    private let log: KIDLog
    private let tasks: TaskTracker
    private let reconnectBase: Int

    private var challengeId: String?
    private var fellBack = false
    private var task: Task<Void, Never>?
    private var generation = 0
    private var snapshot = false

    init(
        client: any KIDClient,
        onStatus: @escaping @MainActor (ChallengeStatus) async throws -> Bool,
        onFallback: @escaping @MainActor () -> Void,
        now: @escaping () -> Date,
        log: @escaping KIDLog,
        tasks: TaskTracker,
        reconnectBaseMs: Int = reconnectBaseMs
    ) {
        self.client = client
        self.onStatus = onStatus
        self.onFallback = onFallback
        self.now = now
        self.log = log
        self.tasks = tasks
        reconnectBase = reconnectBaseMs
    }

    var active: Bool { task != nil }

    /// Streams the challenge's status. Returns false once it has fallen back to polling, which the caller then runs.
    func start(_ id: String) -> Bool {
        if id != challengeId {
            stop()
            challengeId = id
            fellBack = false
        }
        if fellBack { return false }
        if task != nil { return true }
        generation += 1
        let current = generation
        task = tasks.spawn { [weak self] in await self?.run(id, current) }
        return true
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func run(_ id: String, _ current: Int) async {
        var failedOpens = 0
        var backoff = reconnectBase
        func nextBackoff() -> Int {
            defer { backoff = min(backoff * 2, reconnectMaxMs) }
            return backoff
        }
        func failOpen(unavailable: Bool) -> Int? {
            failedOpens += 1
            guard unavailable || failedOpens >= maxFailedOpens else { return nextBackoff() }
            guard generation == current else { return nil }
            task = nil
            fellBack = true
            onFallback()
            return nil
        }
        while !Task.isCancelled {
            let openedAt = now()
            let delay: Int
            snapshot = false
            do {
                let end = try await client.challengeStream(id) { [weak self] status in
                    guard let self, generation == current, !Task.isCancelled else { return }
                    snapshot = true
                    var keepWatching = true
                    do {
                        keepWatching = try await onStatus(status)
                    } catch {
                        // The stream re-sends the status on reconnect, so a failed handling is retried then.
                        log(.error, "could not handle a challenge status; will retry \(error)")
                    }
                    if !keepWatching && generation == current { stop() }
                }
                if Task.isCancelled { return }
                // A proxy can pass the headers and hold or drop the body, so an open only counts once a status arrives.
                if !snapshot {
                    guard let next = failOpen(unavailable: false) else { return }
                    delay = next
                } else if case .closed(let retryMs) = end, now().timeIntervalSince(openedAt) >= minHealthyStreamSeconds {
                    backoff = reconnectBase
                    failedOpens = 0
                    delay = retryMs ?? 0
                } else {
                    failedOpens = 0
                    delay = nextBackoff()
                }
            } catch {
                if Task.isCancelled { return }
                guard let next = failOpen(unavailable: (error as? KIDError)?.code == .notFound) else { return }
                delay = next
            }
            if delay > 0 { try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000) }
        }
    }
}
