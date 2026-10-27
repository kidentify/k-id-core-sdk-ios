import Foundation

@MainActor
public struct UseKIDAgeGate {
    public let status: KIDStatus
    public let challengeId: String?
    public let challengeKind: KIDChallengeKind?
    public let sessionId: String?
    /// Why the gate ended in `.error`: a k-ID API error as is, and any other failure as `.unavailable`.
    public let error: KIDError?
    public let requirements: Requirements?
    /// Send the challenge email. Valid only after a challenge exists; re-callable to re-send a correction.
    public let submit: () async -> KIDResult
}

@MainActor
public struct UseKIDSession {
    public let session: Session?
    public let permissions: [PermissionName: Bool]
    public let sessionId: String?
    public let isLoaded: Bool
    public let ageVerification: AgeVerification?
    public let verifyAge: UseKIDSessionVerifyAge
    public let refresh: () async throws -> Void
}

/// Client permissions gate what a player SEES; enforce the real capability server-side.
public struct UseKIDPermission {
    private let byName: [PermissionName: Permission]

    init(_ permissions: [Permission]) {
        byName = Dictionary(permissions.map { ($0.permissionName, $0) }, uniquingKeysWith: { _, last in last })
    }

    public func can(_ name: PermissionName) -> Bool { byName[name]?.enabled ?? false }
    public func get(_ name: PermissionName) -> Permission? { byName[name] }
}

public struct UseKIDChallenge {
    public let challengeId: String?
    public let status: RawChallengeStatus?
    public let expiresAt: Date?
}

@MainActor
public struct UseKIDPermissionSettings {
    public let permissions: [Permission]
    public let isLoaded: Bool
    /// Why the session failed to load, or nil; show an error and call `refresh()` to retry.
    public let error: KIDError?
    public let change: (PermissionName, Bool) async -> KIDResult
    public let hasApproverEmail: Bool
    let upgradeAction: ([PermissionName], String?) async -> KIDResult
    /// Asks the grownup to approve all of `names` in one email. Pass `approverEmail` when `hasApproverEmail` is false.
    ///
    /// A permission with a `verifiedAgeThreshold` needs the player's own age check instead: without an email this
    /// returns `invalidRequest` when that check is needed; call it again with the player's own email.
    public func upgrade(_ names: [PermissionName], approverEmail: String? = nil) async -> KIDResult {
        await upgradeAction(names, approverEmail)
    }
    public let challenge: SettingsChallengeState
    public let refresh: () async -> Void
}

extension AgeGateController {
    public var ageGate: UseKIDAgeGate {
        UseKIDAgeGate(
            status: state.status,
            challengeId: state.challengeId,
            challengeKind: state.challengeKind,
            sessionId: state.sessionId,
            error: state.error,
            requirements: state.requirements,
            submit: { [weak self] in await self?.submit() ?? KIDResult(ok: false, error: localKIDError()) }
        )
    }

    public var session: UseKIDSession {
        var permissions: [PermissionName: Bool] = [:]
        for p in state.session?.permissions ?? [] { permissions[p.permissionName] = p.enabled }
        return UseKIDSession(
            session: state.session,
            permissions: permissions,
            sessionId: state.sessionId,
            isLoaded: state.session != nil,
            ageVerification: state.session?.ageVerification,
            verifyAge: sessionVerifyAgeHook,
            refresh: { [weak self] in try await self?.refreshSession() }
        )
    }

    private var sessionVerifyAgeHook: UseKIDSessionVerifyAge {
        let controller = sessionVerifyAge()
        let state = controller?.state ?? VerifyAgeState(status: .running)
        return UseKIDSessionVerifyAge(
            status: state.status,
            step: state.step,
            challengeId: state.challengeId,
            rawChallengeStatus: state.rawChallengeStatus,
            expiresAt: state.expiresAt,
            error: state.error,
            start: { controller?.start() },
            submitAction: { email in
                guard let controller else { return KIDResult(ok: false, error: localKIDError()) }
                controller.setEmail(email)
                return await controller.submit()
            }
        )
    }

    public var permission: UseKIDPermission { UseKIDPermission(state.session?.permissions ?? []) }

    public var challenge: UseKIDChallenge {
        UseKIDChallenge(challengeId: state.challengeId, status: state.rawChallengeStatus, expiresAt: state.expiresAt)
    }
}

@MainActor
public struct UseKIDSessionVerifyAge {
    public let status: KIDStatus
    public let step: VerifyAgeStep?
    public let challengeId: String?
    public let rawChallengeStatus: RawChallengeStatus?
    public let expiresAt: Date?
    /// Why the check ended in `.error`: a k-ID API error as is, and any other failure as `.unavailable`.
    public let error: KIDError?
    /// Checks the session is a verified adult, minting a challenge when it is not. Idempotent; a no-op until the gate
    /// passes.
    public let start: () -> Void
    let submitAction: (String) async -> KIDResult
    /// Sends the player the verification link. Re-callable to re-send to a corrected address.
    public func submit(_ email: String) async -> KIDResult { await submitAction(email) }
}

extension SettingsController {
    public var permissionSettings: UseKIDPermissionSettings {
        UseKIDPermissionSettings(
            permissions: state.session?.permissions ?? [],
            isLoaded: state.isLoaded,
            error: state.error,
            change: { [weak self] name, enabled in
                await self?.change(name, enabled: enabled) ?? KIDResult(ok: false, error: localKIDError())
            },
            hasApproverEmail: state.session?.hasApproverEmail != false,
            upgradeAction: { [weak self] names, approverEmail in
                await self?.upgrade(names, approverEmail: approverEmail) ?? KIDResult(ok: false, error: localKIDError())
            },
            challenge: state.challenge,
            refresh: { [weak self] in await self?.refresh() }
        )
    }
}
