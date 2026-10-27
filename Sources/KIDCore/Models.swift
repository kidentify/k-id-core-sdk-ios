import Foundation

/// The player's session: their age status and the permissions it grants.
public struct Session: Codable, Hashable, Sendable {
    public var sessionId: String
    public var ageStatus: String
    public var jurisdiction: String?
    public var etag: String?
    /// Whether a grownup is linked to approve upgrades.
    public var hasApproverEmail: Bool?
    public var permissions: [Permission]
    public var ageVerification: AgeVerification?

    public init(
        sessionId: String,
        ageStatus: String,
        jurisdiction: String? = nil,
        etag: String? = nil,
        hasApproverEmail: Bool? = nil,
        permissions: [Permission],
        ageVerification: AgeVerification? = nil
    ) {
        self.sessionId = sessionId
        self.ageStatus = ageStatus
        self.jurisdiction = jurisdiction
        self.etag = etag
        self.hasApproverEmail = hasApproverEmail
        self.permissions = permissions
        self.ageVerification = ageVerification
    }
}

/// The age a player proved, counting birthdays since, and when.
public struct AgeVerification: Codable, Hashable, Sendable {
    public var verifiedAge: Int
    public var verifiedAt: Date

    public init(verifiedAge: Int, verifiedAt: Date) {
        self.verifiedAge = verifiedAge
        self.verifiedAt = verifiedAt
    }
}

/// Who decides whether a permission is on.
public enum ManagedBy: String, Codable, Hashable, Sendable, CaseIterable {
    case player = "PLAYER"
    case guardian = "GUARDIAN"
    case prohibited = "PROHIBITED"
}

public struct Permission: Codable, Hashable, Sendable {
    public var name: String
    public var enabled: Bool
    public var managedBy: ManagedBy?
    /// The age the player must verify before this permission can be enabled; nil when no age check applies.
    public var verifiedAgeThreshold: Int?

    public init(name: String, enabled: Bool, managedBy: ManagedBy? = nil, verifiedAgeThreshold: Int? = nil) {
        self.name = name
        self.enabled = enabled
        self.managedBy = managedBy
        self.verifiedAgeThreshold = verifiedAgeThreshold
    }

    public var permissionName: PermissionName { PermissionName(rawValue: name) }
}

public struct Challenge: Codable, Hashable, Sendable {
    public var challengeId: String
    public var type: String?

    public init(challengeId: String, type: String? = nil) {
        self.challengeId = challengeId
        self.type = type
    }
}

/// The jurisdiction's age rules, and the ways it lets the age gate collect an age.
public struct Requirements: Codable, Hashable, Sendable {
    public var shouldDisplay: Bool
    public var digitalConsentAge: Int?
    public var civilAge: Int?
    public var minimumAge: Int?
    public var accessAge: Int?
    public var approvedAgeCollectionMethods: [String]

    public init(
        shouldDisplay: Bool,
        digitalConsentAge: Int? = nil,
        civilAge: Int? = nil,
        minimumAge: Int? = nil,
        accessAge: Int? = nil,
        approvedAgeCollectionMethods: [String]
    ) {
        self.shouldDisplay = shouldDisplay
        self.digitalConsentAge = digitalConsentAge
        self.civilAge = civilAge
        self.minimumAge = minimumAge
        self.accessAge = accessAge
        self.approvedAgeCollectionMethods = approvedAgeCollectionMethods
    }
}

package struct AgeResult: Codable, Hashable, Sendable {
    package var status: String
    package var session: Session?
    package var challenge: Challenge?
    package var claimToken: String?

    package init(status: String, session: Session? = nil, challenge: Challenge? = nil, claimToken: String? = nil) {
        self.status = status
        self.session = session
        self.challenge = challenge
        self.claimToken = claimToken
    }
}

package struct InviteParentResult: Codable, Hashable, Sendable {
    package var status: String
    package var challenge: Challenge

    package init(status: String, challenge: Challenge) {
        self.status = status
        self.challenge = challenge
    }
}

struct UpgradeSessionResponse: Decodable {
    var session: Session
    var challenge: Challenge?
}

struct VerifySessionAgeResponse: Decodable {
    var status: Schemas.VerifySessionAgeResponse.StatusPayload
    var challenge: Challenge?
}
