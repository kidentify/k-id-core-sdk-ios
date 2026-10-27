import CryptoKit
import DeviceCheck
import Foundation

protocol DeviceKey: Sendable {
    var publicJWK: [String: String] { get }
    /// Returns the raw 64-byte `r || s` signature JWS expects.
    func sign(_ data: Data) throws -> Data
}

protocol DeviceKeyProvider: Sendable {
    func key() throws -> any DeviceKey
}

protocol AppAttestProvider: Sendable {
    var isSupported: Bool { get }
    func generateKey() async throws -> String
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data
}

protocol AppAttestKeyStore: Sendable {
    func load() -> String?
    func save(_ keyId: String?)
}

private func jwk(_ publicKey: P256.Signing.PublicKey) -> [String: String] {
    // x963 is 0x04 || X || Y.
    let point = publicKey.x963Representation
    return [
        "kty": "EC",
        "crv": "P-256",
        "x": base64URL(point.dropFirst().prefix(32)),
        "y": base64URL(point.suffix(32)),
    ]
}

struct SecureEnclaveDeviceKey: DeviceKey {
    let privateKey: SecureEnclave.P256.Signing.PrivateKey
    var publicJWK: [String: String] { jwk(privateKey.publicKey) }
    func sign(_ data: Data) throws -> Data { try privateKey.signature(for: data).rawRepresentation }
}

struct SoftwareDeviceKey: DeviceKey {
    let privateKey: P256.Signing.PrivateKey
    var publicJWK: [String: String] { jwk(privateKey.publicKey) }
    func sign(_ data: Data) throws -> Data { try privateKey.signature(for: data).rawRepresentation }
}

protocol DeviceKeyStore: Sendable {
    func load() throws -> Data?
    func save(_ handle: Data) throws
}

protocol HardwareKeyFactory: Sendable {
    var isAvailable: Bool { get }
    func create() throws -> (key: any DeviceKey, handle: Data)
    func restore(_ handle: Data) throws -> any DeviceKey
}

struct SecureEnclaveKeyFactory: HardwareKeyFactory {
    var isAvailable: Bool { SecureEnclave.isAvailable }
    func create() throws -> (key: any DeviceKey, handle: Data) {
        let key = try SecureEnclave.P256.Signing.PrivateKey()
        return (SecureEnclaveDeviceKey(privateKey: key), key.dataRepresentation)
    }
    func restore(_ handle: Data) throws -> any DeviceKey {
        SecureEnclaveDeviceKey(privateKey: try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: handle))
    }
}

/// Never migrated: on another device the handle would not open the key anyway.
struct KeychainDeviceKeyStore: DeviceKeyStore {
    var service = "com.k-id.core.deviceKey"
    var account = "dpop"

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    func load() throws -> Data? {
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        return item as? Data
    }

    func save(_ handle: Data) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: handle,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let added = SecItemAdd(query.merging(attributes) { $1 } as CFDictionary, nil)
            guard added == errSecSuccess else { throw KeychainError(status: added) }
            return
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
}

struct KeychainError: Error {
    let status: OSStatus
}

final class InstallDeviceKeyProvider: DeviceKeyProvider, @unchecked Sendable {
    static let shared = InstallDeviceKeyProvider()

    private let store: any DeviceKeyStore
    private let hardware: any HardwareKeyFactory
    private let lock = NSLock()
    private var cached: (any DeviceKey)?

    init(store: any DeviceKeyStore = KeychainDeviceKeyStore(), hardware: any HardwareKeyFactory = SecureEnclaveKeyFactory()) {
        self.store = store
        self.hardware = hardware
    }

    func key() throws -> any DeviceKey {
        try lock.withLock {
            if let cached { return cached }
            let key = try load()
            cached = key
            return key
        }
    }

    private func load() throws -> any DeviceKey {
        guard hardware.isAvailable else { return SoftwareDeviceKey(privateKey: P256.Signing.PrivateKey()) }
        let handle: Data?
        do {
            handle = try store.load()
        } catch {
            // An unreadable Keychain (before first unlock) gets a key for this launch; the stored one is kept.
            return try hardware.create().key
        }
        // A handle that no longer opens a key, such as one restored onto another device, is replaced.
        if let handle, let key = try? hardware.restore(handle) {
            return key
        }
        let created = try hardware.create()
        try? store.save(created.handle)
        return created.key
    }
}

struct DeviceCheckAppAttest: AppAttestProvider {
    var isSupported: Bool { DCAppAttestService.shared.isSupported }
    func generateKey() async throws -> String { try await DCAppAttestService.shared.generateKey() }
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
    }
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)
    }
}

struct UserDefaultsAppAttestKeyStore: AppAttestKeyStore {
    var name = "com.k-id.core.appAttestKeyId"
    func load() -> String? { UserDefaults.standard.string(forKey: name) }
    func save(_ keyId: String?) { UserDefaults.standard.set(keyId, forKey: name) }
}

func base64URL(_ data: some DataProtocol) -> String {
    Data(data).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

func jwkThumbprint(_ jwk: [String: String]) -> String {
    let canonical = #"{"crv":"\#(jwk["crv"] ?? "")","kty":"\#(jwk["kty"] ?? "")","x":"\#(jwk["x"] ?? "")","y":"\#(jwk["y"] ?? "")"}"#
    return base64URL(Data(SHA256.hash(data: Data(canonical.utf8))))
}

func dpopProof(_ key: any DeviceKey, method: String, url: URL, nonce: String? = nil, accessToken: String? = nil) throws
    -> String
{
    var target = URLComponents(url: url, resolvingAgainstBaseURL: false)
    target?.query = nil
    target?.fragment = nil
    var claims: [String: Any] = [
        "htm": method,
        "htu": target?.string ?? url.absoluteString,
        "iat": Int(Date().timeIntervalSince1970),
        "jti": UUID().uuidString,
    ]
    if let nonce { claims["nonce"] = nonce }
    if let accessToken { claims["ath"] = base64URL(Data(SHA256.hash(data: Data(accessToken.utf8)))) }
    let header: [String: Any] = ["typ": "dpop+jwt", "alg": "ES256", "jwk": key.publicJWK]
    func part(_ object: [String: Any]) throws -> String {
        base64URL(try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes]))
    }
    let signingInput = "\(try part(header)).\(try part(claims))"
    return "\(signingInput).\(base64URL(try key.sign(Data(signingInput.utf8))))"
}

struct ClientTrustResponse: Sendable {
    var ok: Bool
    var status: Int
    var data: Data
    var retryAfter: Int? = nil
}

@MainActor
final class ClientTrust {
    typealias Send = @MainActor (_ method: String, _ path: String, _ body: Data?, _ headers: [String: String]) async
        -> ClientTrustResponse

    /// A token is refreshed this long before it expires, so a call never races its expiry.
    static let expiryMargin: TimeInterval = 60
    /// So an outage of the mint endpoints doesn't add two requests to every call.
    static let mintCooldown: TimeInterval = 60

    private struct Token {
        var value: String
        var expiresAt: Date
        var trustLevel: Schemas.ClientToken.TrustLevelPayload
    }

    private let send: Send
    private let url: (String) -> URL?
    private let keys: any DeviceKeyProvider
    private let appAttest: (any AppAttestProvider)?
    private let keyStore: any AppAttestKeyStore
    private let now: @Sendable () -> Date
    private let log: KIDLog
    private var token: Token?
    private var minting: Task<Token?, Never>?
    private var nextMintAt = Date.distantPast
    // Nil when the last mint failed before reaching k-ID (no device key), or did not fail.
    private var failure: ClientTrustResponse?

    init(
        send: @escaping Send,
        url: @escaping (String) -> URL?,
        keys: any DeviceKeyProvider = InstallDeviceKeyProvider.shared,
        appAttest: (any AppAttestProvider)? = DeviceCheckAppAttest(),
        keyStore: any AppAttestKeyStore = UserDefaultsAppAttestKeyStore(),
        now: @escaping @Sendable () -> Date = Date.init,
        log: KIDLog? = nil
    ) {
        self.send = send
        self.url = url
        self.keys = keys
        self.appAttest = appAttest
        self.keyStore = keyStore
        self.now = now
        self.log = log ?? defaultLog
    }

    func headers(method: String, path: String) async -> [String: String] {
        guard let token = await current(), let target = url(path), let key = try? keys.key(),
            let proof = try? dpopProof(key, method: method, url: target, accessToken: token.value)
        else { return [:] }
        return ["Kid-Client": token.value, "DPoP": proof]
    }

    /// The trust level of the token this client sends, minting one if it has none; nil when it has none to send.
    func trustLevel() async -> Schemas.ClientToken.TrustLevelPayload? {
        await current()?.trustLevel
    }

    /// The token step's failure that leaves calls without a token, with a 429's `retryAfter` as the seconds left before
    /// the next mint; nil when there is none.
    func tokenFailure() -> ClientTrustResponse? {
        guard var failure else { return nil }
        if failure.status == 429 {
            failure.retryAfter = max(1, Int(nextMintAt.timeIntervalSince(now()).rounded(.up)))
        }
        return failure
    }

    func invalidate() {
        token = nil
    }

    private func current() async -> Token? {
        if let token, token.expiresAt.timeIntervalSinceNow > Self.expiryMargin { return token }
        if now() < nextMintAt { return nil }
        if minting == nil {
            minting = Task { await self.mint() }
        }
        token = await minting?.value
        minting = nil
        // A rate limit's Retry-After replaces the cooldown, so the mint is tried again as soon as k-ID allows.
        if token == nil {
            nextMintAt = now().addingTimeInterval(failure?.retryAfter.map(TimeInterval.init) ?? Self.mintCooldown)
        }
        return token
    }

    private func mint() async -> Token? {
        failure = nil
        guard let key = try? keys.key() else { return nil }
        let challenge = await send("POST", "/client/challenge", Data("{}".utf8), [:])
        if !challenge.ok {
            failure = challenge
            return nil
        }
        guard let issued = try? HTTPClient.decoder.decode(Schemas.ClientChallenge.self, from: challenge.data)
        else { return nil }

        let clientDataHash = Data(SHA256.hash(data: Data("\(issued.nonce).\(jwkThumbprint(key.publicJWK))".utf8)))
        let evidence = await evidence(clientDataHash)
        let body = evidence ?? Schemas.ClientAttestRequest(platform: .ios)

        guard let target = url("/client/attest"),
            let proof = try? dpopProof(key, method: "POST", url: target, nonce: issued.nonce),
            let encoded = try? JSONEncoder().encode(body)
        else { return nil }
        let attested = await send("POST", "/client/attest", encoded, ["DPoP": proof])
        if !attested.ok {
            failure = attested
            return nil
        }
        guard let minted = try? HTTPClient.decoder.decode(Schemas.ClientToken.self, from: attested.data)
        else { return nil }
        if minted.trustLevel == .verified {
            if body.attestation != nil { keyStore.save(body.keyId) }
        } else if appAttest != nil {
            // A key the server didn't accept is dropped, so the next mint attests a fresh one.
            if body.keyId != nil { keyStore.save(nil) }
            log(.warn, "App Attest failed. It works only in App Store and TestFlight builds; use a test key while developing.")
        }
        return Token(value: minted.clientToken, expiresAt: minted.expiresAt, trustLevel: minted.trustLevel)
    }

    private func evidence(_ clientDataHash: Data) async -> Schemas.ClientAttestRequest? {
        guard let appAttest, appAttest.isSupported else { return nil }
        var body = Schemas.ClientAttestRequest(platform: .ios)
        do {
            if let keyId = keyStore.load() {
                body.keyId = keyId
                body.assertion = try await appAttest.generateAssertion(keyId, clientDataHash: clientDataHash).base64EncodedString()
            } else {
                let keyId = try await appAttest.generateKey()
                body.keyId = keyId
                body.attestation = try await appAttest.attestKey(keyId, clientDataHash: clientDataHash).base64EncodedString()
            }
            return body
        } catch {
            // A key the OS no longer honours is dropped; the next mint attests a new one.
            keyStore.save(nil)
            return nil
        }
    }
}
