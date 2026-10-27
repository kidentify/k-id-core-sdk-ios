import Foundation

typealias Schemas = Components.Schemas

package typealias ChallengeStatus = Components.Schemas.ChallengeStatus

package typealias DeclareInput = KIDDeclare

public enum AgeSignal: Hashable, Sendable {
    case dateOfBirth(String)
    case age(Int)
}

extension Components.Schemas.ChallengeStatus {
    var permissionNames: [PermissionName]? { permissions?.map(PermissionName.init(rawValue:)) }
}

/// Read once when the provider appears, and applied only while you use a test key.
public struct KIDDeclare: Hashable, Sendable {
    public struct Permission: Hashable, Sendable {
        public var name: PermissionName

        public init(name: PermissionName) {
            self.name = name
        }
    }

    public var permissions: [Permission]
    public var privacyPolicyUrl: DeclareField<String>
    public var termsOfServiceUrl: DeclareField<String>
    /// A public https link, or an image in the app (a file URL or path), which the SDK reads and sends inline.
    public var iconUrl: DeclareField<String>
    /// Required. The address k-ID's emails give players and parents for help.
    public var supportEmail: String

    public init(
        permissions: [Permission],
        privacyPolicyUrl: DeclareField<String> = .keep,
        termsOfServiceUrl: DeclareField<String> = .keep,
        iconUrl: DeclareField<String> = .keep,
        supportEmail: String
    ) {
        self.permissions = permissions
        self.privacyPolicyUrl = privacyPolicyUrl
        self.termsOfServiceUrl = termsOfServiceUrl
        self.iconUrl = iconUrl
        self.supportEmail = supportEmail
    }
}

/// An optional declared value. Leave it as `.keep` to keep what k-ID has, `.clear` (or `nil`) to clear it, or set it.
public enum DeclareField<Value: Hashable & Sendable>: Hashable, Sendable, ExpressibleByNilLiteral {
    case keep
    case clear
    case set(Value)

    public init(nilLiteral: ()) { self = .clear }
}

extension DeclareField: ExpressibleByUnicodeScalarLiteral, ExpressibleByExtendedGraphemeClusterLiteral,
    ExpressibleByStringLiteral
where Value == String {
    public init(stringLiteral value: String) { self = .set(value) }
}

private struct DeclareBody: Encodable {
    var input: KIDDeclare
    var iconUrl: DeclareField<String>

    enum Keys: String, CodingKey { case permissions, privacyPolicyUrl, termsOfServiceUrl, iconUrl, supportEmail }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encode(input.permissions.map { Schemas.DeclaredPermission(name: $0.name.rawValue) }, forKey: .permissions)
        try encode(input.privacyPolicyUrl, .privacyPolicyUrl, &c)
        try encode(input.termsOfServiceUrl, .termsOfServiceUrl, &c)
        try encode(iconUrl, .iconUrl, &c)
        try c.encode(input.supportEmail, forKey: .supportEmail)
    }

    private func encode<V: Encodable>(_ field: DeclareField<V>, _ key: Keys, _ c: inout KeyedEncodingContainer<Keys>) throws {
        switch field {
        case .keep: break
        case .clear: try c.encodeNil(forKey: key)
        case .set(let value): try c.encode(value, forKey: key)
        }
    }
}

extension DeclareField {
    func map<T>(_ transform: (Value) -> T) -> DeclareField<T> {
        switch self {
        case .keep: .keep
        case .clear: .clear
        case .set(let value): .set(transform(value))
        }
    }
}

/// The icon as declare sends it: a public https link as is, anything k-ID cannot reach read here and inlined.
func declaredIconUrl(_ iconUrl: String, fetch: KIDTransport) async throws -> String {
    if iconUrl.hasPrefix("data:") || iconUrl.isEmpty { return iconUrl }
    let url = URL(string: iconUrl).flatMap { $0.scheme == nil ? nil : $0 } ?? URL(fileURLWithPath: iconUrl)
    let host = url.host?.lowercased() ?? ""
    let local = host == "localhost" || host.hasSuffix(".local") || host.hasSuffix(".localhost") || host.hasPrefix("[")
        || host.allSatisfy { $0.isNumber || $0 == "." }
    if url.scheme == "https", !local { return iconUrl }
    let data: Data
    if url.isFileURL {
        do { data = try Data(contentsOf: url) } catch {
            throw KIDError(status: 0, code: .invalidRequest, message: "Could not read the app icon at \(iconUrl).", rawCode: nil)
        }
    } else {
        let (body, response) = try await fetch(URLRequest(url: url))
        guard (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? false else {
            throw KIDError(status: 0, code: .invalidRequest, message: "Could not read the app icon at \(iconUrl).", rawCode: nil)
        }
        data = body
    }
    let type = data.starts(with: [0x89, 0x50, 0x4E, 0x47]) ? "image/png" : data.starts(with: [0xFF, 0xD8]) ? "image/jpeg" : "application/octet-stream"
    return "data:\(type);base64,\(data.base64EncodedString())"
}

package struct SessionRead: Sendable {
    var session: Session?
    var etag: String?
    var notModified: Bool
    /// k-ID's answer when the session no longer exists.
    var notFound: KIDError? = nil
}

package enum SessionChangeResult: Sendable {
    case ok(Session)
    case failed(KIDError)
}

package struct SessionUpgradeResult: Sendable {
    var session: Session
    var challenge: Challenge?
}

package struct SessionVerifyAgeResult: Sendable {
    var status: Schemas.VerifySessionAgeResponse.StatusPayload
    var challenge: Challenge?
}

package struct SendEmailResult: Sendable {
    var ok: Bool
    var error: KIDError?
}

public enum KIDErrorCode: String, Sendable {
    case invalidRequest = "invalid_request"
    case unauthorized
    case notFound = "not_found"
    case rateLimited = "rate_limited"
    case unavailable
}

// The API returns almost every error as HTTP 400, so map on the JSON `error` code, not the status.
private let rawErrorToCode: [String: KIDErrorCode] = [
    "NOT_FOUND": .notFound,
    "UNAUTHORIZED": .unauthorized,
    "TOO_MANY_REQUESTS": .rateLimited,
    "INVALID_INPUT": .invalidRequest,
    "INVALID_EMAIL": .invalidRequest,
    "AGE_CONFLICT": .invalidRequest,
    "FEATURE_DISABLED": .unavailable,
    "CANNOT_RESOLVE_JURISDICTION": .unavailable,
    "INTERNAL_ERROR": .unavailable,
    "UNKNOWN": .unavailable,
]

func toKIDErrorCode(_ rawCode: String?, _ status: Int) -> KIDErrorCode {
    if let rawCode, let code = rawErrorToCode[rawCode] { return code }
    if status == 429 { return .rateLimited }
    if status == 401 || status == 403 { return .unauthorized }
    if status == 404 { return .notFound }
    if status >= 400 && status < 500 { return .invalidRequest }
    return .unavailable
}

enum KIDErrorMessage: String {
    case invalidRequest = "The request was invalid."
    case invalidAgeSignal = "Provide a valid date of birth or age."
    case invalidJurisdiction = "Unknown or invalid jurisdiction code."
    case ageConflict = "The platform age signal conflicts with the provided age."
    case challengeIdRequired = "A challenge id is required."
    case challengeResolved = "This challenge is already resolved; no email can be sent."
    case emailMismatch = "The email address doesn't match this challenge's approver, or is required."
    case permissionNotChangeable = "That permission can't be changed here."
    case unauthorizedKey = "Invalid or unrecognized publishable key."
    case unauthorizedApp = "This app isn't allowed to use your publishable key."
    case sessionNotFound = "Session not found."
    case challengeNotFound = "Challenge not found."
    case rateLimited = "Too many requests. Please wait and try again."
    case serverError = "Something went wrong on our side. Please try again."
    case featureDisabled = "This feature isn't enabled for this product."
}

private let invalidInputSubcases: [(pattern: String, message: KIDErrorMessage)] = [
    ("invalid jurisdiction", .invalidJurisdiction),
    ("dateofbirth|date of birth", .invalidAgeSignal),
    ("challenge id must be provided", .challengeIdRequired),
    ("completed challenge", .challengeResolved),
]

struct MessageKeys {
    var notFound: KIDErrorMessage?
    var invalid: KIDErrorMessage?
}

func resolveErrorMessage(_ rawCode: String?, _ rawMessage: String?, _ status: Int, _ keys: MessageKeys) -> String {
    switch rawCode {
    case "AGE_CONFLICT": return KIDErrorMessage.ageConflict.rawValue
    case "INVALID_EMAIL": return KIDErrorMessage.emailMismatch.rawValue
    case "FEATURE_DISABLED": return KIDErrorMessage.featureDisabled.rawValue
    case "TOO_MANY_REQUESTS": return KIDErrorMessage.rateLimited.rawValue
    case "UNAUTHORIZED":
        return (status == 403 ? KIDErrorMessage.unauthorizedApp : .unauthorizedKey).rawValue
    case "INTERNAL_ERROR": return KIDErrorMessage.serverError.rawValue
    case "NOT_FOUND": return (keys.notFound ?? .sessionNotFound).rawValue
    default: break
    }
    if status == 429 { return KIDErrorMessage.rateLimited.rawValue }
    if status == 401 || status == 403 {
        return (status == 403 ? KIDErrorMessage.unauthorizedApp : .unauthorizedKey).rawValue
    }
    if status >= 500 || status == 0 { return KIDErrorMessage.serverError.rawValue }
    let subcase = rawMessage.flatMap { message in
        invalidInputSubcases.first { message.range(of: $0.pattern, options: [.regularExpression, .caseInsensitive]) != nil }
    }
    return (subcase?.message ?? keys.invalid ?? .invalidRequest).rawValue
}

/// The error a failure the SDK catches before any call carries, such as a submit before a challenge exists.
func localKIDError() -> KIDError {
    KIDError(status: 0, code: .invalidRequest, message: KIDErrorMessage.invalidRequest.rawValue)
}

/// Anything that is not already a KIDError, such as a dropped connection, becomes the transport error.
func toKIDError(_ error: Error?) -> KIDError {
    error as? KIDError ?? KIDError(status: 0, code: .unavailable, message: KIDErrorMessage.serverError.rawValue)
}

/// Retry-After as a whole number of seconds; anything else, an HTTP date or an overflow included, is left out.
func parseRetryAfter(_ header: String?) -> Int? {
    guard let value = header?.trimmingCharacters(in: .whitespaces), !value.isEmpty,
        value.allSatisfy({ $0.isASCII && $0.isNumber })
    else { return nil }
    return Int(value)
}

/// `message` is safe to show a player; it is never raw server text.
public struct KIDError: Error, LocalizedError, CustomStringConvertible, Sendable {
    public let status: Int
    public let code: KIDErrorCode
    public let message: String
    public let rawCode: String?
    /// With `.rateLimited`, the whole seconds k-ID asked the caller to wait before trying again, when it said.
    public let retryAfter: Int?

    package init(status: Int, code: KIDErrorCode, message: String, rawCode: String? = nil, retryAfter: Int? = nil) {
        self.status = status
        self.code = code
        self.message = message
        self.rawCode = rawCode
        self.retryAfter = retryAfter
    }

    public var errorDescription: String? { message }

    public var description: String {
        "KIDError(status=\(status), code=\(code.rawValue), rawCode=\(rawCode ?? "nil"), message=\(message))"
    }
}

package typealias KIDTransport = @Sendable (URLRequest) async throws -> (Data, URLResponse)
/// Opens a streaming request, handing back the response and its body in chunks.
package typealias KIDStreamTransport = @Sendable (URLRequest) async throws -> (URLResponse, AsyncThrowingStream<Data, Error>)

private let lineFeed = UInt8(ascii: "\n")
private let carriageReturn = UInt8(ascii: "\r")

// Yields the body a line at a time rather than a byte at a time, so its reader wakes once per line.
private let urlSessionStreamTransport: KIDStreamTransport = { request in
    let (bytes, response) = try await URLSession.shared.bytes(for: request)
    let body = AsyncThrowingStream<Data, Error> { continuation in
        let reader = Task {
            var chunk = Data()
            do {
                for try await byte in bytes {
                    chunk.append(byte)
                    if byte == lineFeed || byte == carriageReturn {
                        continuation.yield(chunk)
                        chunk.removeAll(keepingCapacity: true)
                    }
                }
                if !chunk.isEmpty { continuation.yield(chunk) }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in reader.cancel() }
    }
    return (response, body)
}

package struct ClientOptions: Sendable {
    var publishableKey: String?
    var baseURL: URL
    // Sent as `Kid-App-Id`, which stands in for the `Origin` a native request lacks.
    var appId: String?
    var transport: KIDTransport?
    var streamTransport: KIDStreamTransport?
    var deviceKeys: any DeviceKeyProvider = InstallDeviceKeyProvider.shared
    var appAttest: any AppAttestProvider = DeviceCheckAppAttest()
    var appAttestKeyStore: any AppAttestKeyStore = UserDefaultsAppAttestKeyStore()
    var now: @Sendable () -> Date = Date.init
    var log: KIDLog?

    package init(
        publishableKey: String?,
        baseURL: URL,
        appId: String? = Bundle.main.bundleIdentifier,
        transport: KIDTransport? = nil,
        streamTransport: KIDStreamTransport? = nil
    ) {
        self.publishableKey = publishableKey
        self.baseURL = baseURL
        self.appId = appId
        self.transport = transport
        self.streamTransport = streamTransport
    }
}

@MainActor
package protocol KIDClient: AnyObject {
    func ageGateCheck(_ age: AgeSignal?, platformAgeSignal: PlatformAgeSignal?, jurisdiction: String?) async throws
        -> AgeResult
    /// Whether the server will use a platform age signal from this client: an App Attest-verified app on a live key,
    /// any app on a test key.
    func platformAgeSignalTrusted() async -> Bool
    func getRequirements(jurisdiction: String?) async throws -> Requirements
    func sessionGet(_ sessionId: String, etag: String?) async throws -> SessionRead
    func challengeGetStatus(_ challengeId: String) async throws -> ChallengeStatus
    /// Streams the challenge's status, awaiting `onStatus` for each one in turn, until the stream ends or the task is
    /// cancelled. Throws a `KIDError` when the stream can't be opened; `.notFound` means streaming is unavailable, so
    /// poll instead.
    func challengeStream(_ challengeId: String, onStatus: @escaping @MainActor (ChallengeStatus) async -> Void)
        async throws -> ChallengeStreamEnd
    func challengeSendEmail(_ challengeId: String, email: String?) async -> SendEmailResult
    func challengeInviteParent(_ sessionId: String, parentEmail: String, playerName: String?) async throws
        -> InviteParentResult
    func sessionChange(_ sessionId: String, name: PermissionName, enabled: Bool) async -> SessionChangeResult
    func sessionUpgrade(_ sessionId: String, permissionNames: [PermissionName]) async throws -> SessionUpgradeResult
    func sessionVerifyAge(_ sessionId: String) async throws -> SessionVerifyAgeResult
    func declare(_ input: DeclareInput) async throws
}

@MainActor
package func createClient(_ options: ClientOptions) -> any KIDClient {
    HTTPClient(options)
}

private let knownManagedBy = Set(ManagedBy.allCases.map(\.rawValue))

// Drops an unknown `managedBy` so a new server value can't fail the whole response.
func withoutUnknownManagedBy(_ data: Data) -> Data {
    func clean(_ value: Any) -> Any {
        if var object = value as? [String: Any] {
            if let managedBy = object["managedBy"] as? String, !knownManagedBy.contains(managedBy) {
                object["managedBy"] = nil
            }
            return object.mapValues(clean)
        }
        if let array = value as? [Any] { return array.map(clean) }
        return value
    }
    guard
        let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
        let cleaned = try? JSONSerialization.data(withJSONObject: clean(json), options: .fragmentsAllowed)
    else { return data }
    return cleaned
}

private struct ErrorBody: Decodable {
    var error: String?
    var errorMessage: String?
}

private struct Response {
    var ok: Bool
    var status: Int
    var data: Data
    var etag: String?
    var retryAfter: Int?

    func decode<T: Decodable>(_ type: T.Type) -> T? {
        try? HTTPClient.decoder.decode(type, from: withoutUnknownManagedBy(data))
    }

    var errorBody: ErrorBody { decode(ErrorBody.self) ?? ErrorBody() }
}

private let uriComponentAllowed = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()"
)

private func encodeURIComponent(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: uriComponentAllowed) ?? value
}

@MainActor
final class HTTPClient: KIDClient {
    nonisolated static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let date = parseISODate(raw) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "bad date \(raw)"))
        }
        return decoder
    }()

    private let publishableKey: String?
    private let appId: String?
    private let baseURL: String
    private let transport: KIDTransport
    private let streamTransport: KIDStreamTransport
    private var clientTrust: ClientTrust?

    init(_ options: ClientOptions) {
        publishableKey = options.publishableKey
        appId = options.appId
        var base = options.baseURL.absoluteString
        while base.hasSuffix("/") { base.removeLast() }
        baseURL = base
        transport = options.transport ?? { try await URLSession.shared.data(for: $0) }
        streamTransport = options.streamTransport ?? urlSessionStreamTransport
        if let publishableKey = options.publishableKey {
            clientTrust = ClientTrust(
                send: { [unowned self] method, path, body, headers in
                    let response = await self.rawSend(method, path, body: body, headers: headers)
                    return ClientTrustResponse(
                        ok: response.ok, status: response.status, data: response.data, retryAfter: response.retryAfter)
                },
                url: { [base] path in URL(string: base + path) },
                keys: options.deviceKeys,
                // A test key always mints basic, so it never spends an App Attest key.
                appAttest: publishableKey.hasPrefix("kgp_live_") ? options.appAttest : nil,
                keyStore: options.appAttestKeyStore,
                now: options.now,
                log: options.log
            )
        }
    }

    private func kidError(_ response: Response, _ keys: MessageKeys = MessageKeys()) -> KIDError {
        let body = response.errorBody
        let code = toKIDErrorCode(body.error, response.status)
        return KIDError(
            status: response.status,
            code: code,
            message: resolveErrorMessage(body.error, body.errorMessage, response.status, keys),
            rawCode: body.error,
            retryAfter: code == .rateLimited ? response.retryAfter : nil
        )
    }

    private func send(_ method: String, _ path: String, body: Data? = nil, headers: [String: String] = [:]) async
        -> Response
    {
        guard let clientTrust else { return await rawSend(method, path, body: body, headers: headers) }
        func attempt() async -> Response {
            let trust = await clientTrust.headers(method: method, path: path)
            let response = await rawSend(method, path, body: body, headers: headers.merging(trust) { $1 })
            return tokenFailure(response.status, trust) ?? response
        }
        let first = await attempt()
        guard first.errorBody.error == "CLIENT_TOKEN_INVALID" else { return first }
        clientTrust.invalidate()
        return await attempt()
    }

    /// A call that went out without a token and came back 401 reports why it had none: the token step's own failure.
    private func tokenFailure(_ status: Int, _ trust: [String: String]) -> Response? {
        guard status == 401, trust.isEmpty, let failure = clientTrust?.tokenFailure() else { return nil }
        return Response(ok: false, status: failure.status, data: failure.data, retryAfter: failure.retryAfter)
    }

    private func request(_ method: String, _ path: String, body: Data? = nil, headers: [String: String] = [:])
        -> URLRequest?
    {
        guard let url = URL(string: baseURL + path) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let publishableKey { request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization") }
        if let appId { request.setValue(appId, forHTTPHeaderField: "Kid-App-Id") }
        for (name, value) in headers { request.setValue(value, forHTTPHeaderField: name) }
        return request
    }

    private func rawSend(_ method: String, _ path: String, body: Data? = nil, headers: [String: String] = [:]) async
        -> Response
    {
        guard let request = request(method, path, body: body, headers: headers) else {
            return Response(ok: false, status: 0, data: Data())
        }
        do {
            let (data, urlResponse) = try await transport(request)
            let http = urlResponse as? HTTPURLResponse
            let status = http?.statusCode ?? 0
            return Response(
                ok: (200..<300).contains(status),
                status: status,
                data: data,
                etag: http?.value(forHTTPHeaderField: "ETag"),
                retryAfter: status == 429 ? parseRetryAfter(http?.value(forHTTPHeaderField: "Retry-After")) : nil
            )
        } catch {
            return Response(ok: false, status: 0, data: Data())
        }
    }

    private func post(_ path: String, _ body: some Encodable) async -> Response {
        let data = (try? JSONEncoder().encode(body)) ?? Data("{}".utf8)
        return await send("POST", path, body: data)
    }

    private func decoded<T: Decodable>(_ response: Response, _ type: T.Type, _ keys: MessageKeys = MessageKeys())
        throws -> T
    {
        guard response.ok else { throw kidError(response, keys) }
        guard let value = response.decode(type) else {
            throw KIDError(status: response.status, code: .unavailable, message: KIDErrorMessage.serverError.rawValue, rawCode: nil)
        }
        return value
    }

    func ageGateCheck(_ age: AgeSignal?, platformAgeSignal: PlatformAgeSignal?, jurisdiction: String?) async throws
        -> AgeResult
    {
        var body = Schemas.CheckAgeGateRequest(
            jurisdiction: jurisdiction.flatMap { $0.isEmpty ? nil : $0 }, platformAgeSignal: platformAgeSignal)
        switch age {
        case .dateOfBirth(let dateOfBirth): body.dateOfBirth = dateOfBirth
        case .age(let age): body.age = age
        case nil: break
        }
        let response = await post("/age-gate/check", body)
        return try decoded(response, AgeResult.self, MessageKeys(invalid: .invalidAgeSignal))
    }

    func platformAgeSignalTrusted() async -> Bool {
        guard let clientTrust, let trustLevel = await clientTrust.trustLevel() else { return false }
        return publishableKey?.hasPrefix("kgp_live_") == false || trustLevel == .verified
    }

    func getRequirements(jurisdiction: String?) async throws -> Requirements {
        let query = jurisdiction.flatMap { $0.isEmpty ? nil : "?jurisdiction=\(encodeURIComponent($0))" } ?? ""
        let response = await send("GET", "/age-gate/get-requirements\(query)")
        return try decoded(response, Requirements.self, MessageKeys(invalid: .invalidJurisdiction))
    }

    func sessionGet(_ sessionId: String, etag: String?) async throws -> SessionRead {
        let response = await send(
            "GET",
            "/session/get?sessionId=\(encodeURIComponent(sessionId))",
            headers: etag.map { ["If-None-Match": $0] } ?? [:]
        )
        if response.status == 304 { return SessionRead(session: nil, etag: etag, notModified: true) }
        if !response.ok {
            let err = kidError(response, MessageKeys(notFound: .sessionNotFound))
            if err.code == .notFound { return SessionRead(session: nil, etag: nil, notModified: false, notFound: err) }
            throw err
        }
        let session = try decoded(response, Session.self)
        return SessionRead(session: session, etag: session.etag ?? response.etag, notModified: false)
    }

    func challengeGetStatus(_ challengeId: String) async throws -> ChallengeStatus {
        let response = await send("GET", "/challenge/get-status?challengeId=\(encodeURIComponent(challengeId))")
        return try decoded(response, ChallengeStatus.self, MessageKeys(notFound: .challengeNotFound))
    }

    func challengeStream(_ challengeId: String, onStatus: @escaping @MainActor (ChallengeStatus) async -> Void)
        async throws -> ChallengeStreamEnd
    {
        let path = "/challenge/stream?challengeId=\(encodeURIComponent(challengeId))"
        let unavailable = KIDError(status: 0, code: .unavailable, message: KIDErrorMessage.serverError.rawValue)
        let keys = MessageKeys(notFound: .challengeNotFound)

        var trust: [String: String] = [:]
        func open() async throws -> (HTTPURLResponse, AsyncThrowingStream<Data, Error>) {
            trust = await clientTrust?.headers(method: "GET", path: path) ?? [:]
            let headers = ["Accept": "text/event-stream"].merging(trust) { $1 }
            guard let request = request("GET", path, headers: headers) else { throw unavailable }
            do {
                let (response, body) = try await streamTransport(request)
                guard let http = response as? HTTPURLResponse else { throw unavailable }
                return (http, body)
            } catch {
                throw unavailable
            }
        }
        func refused(_ response: HTTPURLResponse, _ body: AsyncThrowingStream<Data, Error>) async -> KIDError {
            if let failure = tokenFailure(response.statusCode, trust) { return kidError(failure, keys) }
            var data = Data()
            do {
                for try await chunk in body { data.append(chunk) }
            } catch {}
            return kidError(Response(ok: false, status: response.statusCode, data: data), keys)
        }

        var (response, body) = try await open()
        if !(200..<300).contains(response.statusCode) {
            let err = await refused(response, body)
            guard let clientTrust, err.rawCode == "CLIENT_TOKEN_INVALID" else { throw err }
            clientTrust.invalidate()
            (response, body) = try await open()
            if !(200..<300).contains(response.statusCode) { throw await refused(response, body) }
        }
        // A proxy that answers with something other than a stream can't stream to this client.
        guard response.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("text/event-stream") == true else {
            throw unavailable
        }

        var parser = SSEParser()
        do {
            for try await chunk in body {
                for byte in chunk {
                    guard let event = parser.push(byte), event.event == "status",
                        let status = try? HTTPClient.decoder.decode(
                            ChallengeStatus.self, from: withoutUnknownManagedBy(Data(event.data.utf8)))
                    else { continue }
                    await onStatus(status)
                }
            }
        } catch {
            return .dropped
        }
        if Task.isCancelled { return .dropped }
        return .closed(retryMs: parser.retryMs)
    }

    func challengeSendEmail(_ challengeId: String, email: String?) async -> SendEmailResult {
        let body = Schemas.SendEmailRequest(challengeId: challengeId, email: email.flatMap { $0.isEmpty ? nil : $0 })
        let response = await post("/challenge/send-email", body)
        if response.ok { return SendEmailResult(ok: true) }
        return SendEmailResult(
            ok: false, error: kidError(response, MessageKeys(notFound: .challengeNotFound, invalid: .challengeResolved)))
    }

    func challengeInviteParent(_ sessionId: String, parentEmail: String, playerName: String?) async throws
        -> InviteParentResult
    {
        let body = Schemas.InviteParentRequest(
            sessionId: sessionId,
            parentEmail: parentEmail,
            playerName: playerName.flatMap { $0.isEmpty ? nil : $0 }
        )
        let response = await post("/challenge/invite-parent", body)
        return try decoded(response, InviteParentResult.self, MessageKeys(notFound: .sessionNotFound))
    }

    func sessionChange(_ sessionId: String, name: PermissionName, enabled: Bool) async -> SessionChangeResult {
        let body = Schemas.ChangeSessionRequest(sessionId: sessionId, name: name.rawValue, enabled: enabled)
        let response = await post("/session/change", body)
        if response.ok {
            if let session = response.decode(Session.self) { return .ok(session) }
            return .failed(
                KIDError(status: response.status, code: .unavailable, message: KIDErrorMessage.serverError.rawValue))
        }
        return .failed(kidError(response, MessageKeys(notFound: .sessionNotFound, invalid: .permissionNotChangeable)))
    }

    func sessionUpgrade(_ sessionId: String, permissionNames: [PermissionName]) async throws -> SessionUpgradeResult {
        let body = Schemas.UpgradeSessionRequest(
            sessionId: sessionId,
            requestedPermissions: permissionNames.map { Schemas.RequestedPermission(name: $0.rawValue) }
        )
        let response = await post("/session/upgrade", body)
        let data = try decoded(response, UpgradeSessionResponse.self, MessageKeys(notFound: .sessionNotFound))
        return SessionUpgradeResult(session: data.session, challenge: data.challenge)
    }

    func sessionVerifyAge(_ sessionId: String) async throws -> SessionVerifyAgeResult {
        let response = await post("/session/verify-age", Schemas.VerifySessionAgeRequest(sessionId: sessionId))
        let data = try decoded(response, VerifySessionAgeResponse.self, MessageKeys(notFound: .sessionNotFound))
        return SessionVerifyAgeResult(status: data.status, challenge: data.challenge)
    }

    func declare(_ input: DeclareInput) async throws {
        var iconUrl = input.iconUrl
        if case .set(let value) = iconUrl { iconUrl = .set(try await declaredIconUrl(value, fetch: transport)) }
        let body = DeclareBody(input: input, iconUrl: iconUrl)
        let response = await post("/declare", body)
        if !response.ok {
            let data = response.errorBody
            let code = toKIDErrorCode(data.error, response.status)
            throw KIDError(
                status: response.status,
                code: code,
                message: data.errorMessage ?? data.error ?? "Declare failed.",
                rawCode: data.error,
                retryAfter: code == .rateLimited ? response.retryAfter : nil
            )
        }
    }
}

nonisolated(unsafe) private let isoFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

nonisolated(unsafe) private let isoPlain = ISO8601DateFormatter()

/// RFC 3339 with or without fractional seconds (Go's time encoding drops a zero fraction).
func parseISODate(_ raw: String) -> Date? {
    isoFractional.date(from: raw) ?? isoPlain.date(from: raw)
}
