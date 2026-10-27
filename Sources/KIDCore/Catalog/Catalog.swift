// Generated file. Do not edit.

/// A k-ID capability. `allCases` lists them all.
public struct PermissionName: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

extension PermissionName {
    public static let multiplayer = PermissionName(rawValue: "multiplayer")
    public static let leaderboardAndRankings = PermissionName(rawValue: "leaderboard-and-rankings")
    public static let joinGroups = PermissionName(rawValue: "join-groups")
    public static let publicProfile = PermissionName(rawValue: "public-profile")
    public static let customAvatar = PermissionName(rawValue: "custom-avatar")
    public static let customUsername = PermissionName(rawValue: "custom-username")
    public static let textChatPrivate = PermissionName(rawValue: "text-chat-private")
    public static let textChatPublic = PermissionName(rawValue: "text-chat-public")
    public static let voiceChat = PermissionName(rawValue: "voice-chat")
    public static let videoChat = PermissionName(rawValue: "video-chat")
    public static let onlineStatus = PermissionName(rawValue: "online-status")
    public static let publicFriendList = PermissionName(rawValue: "public-friend-list")
    public static let sendAcceptFriendRequests = PermissionName(rawValue: "send-accept-friend-requests")
    public static let linkToThirdPartyChat = PermissionName(rawValue: "link-to-third-party-chat")
    public static let virtualEvents = PermissionName(rawValue: "virtual-events")
    public static let personalizedRecommendations = PermissionName(rawValue: "personalized-recommendations")
    public static let targetedAds = PermissionName(rawValue: "targeted-ads")
    public static let profiling = PermissionName(rawValue: "profiling")
    public static let pushNotifications = PermissionName(rawValue: "push-notifications")
    public static let shareToSocialMedia = PermissionName(rawValue: "share-to-social-media")
    public static let directMarketing = PermissionName(rawValue: "direct-marketing")
    public static let forums = PermissionName(rawValue: "forums")
    public static let inGamePurchases = PermissionName(rawValue: "in-game-purchases")
    public static let lootBoxesPaidCosmeticOnly = PermissionName(rawValue: "loot-boxes-paid-cosmetic-only")
    public static let lootBoxesPaidGameplayImpacting = PermissionName(rawValue: "loot-boxes-paid-gameplay-impacting")
    public static let lootBoxesKompuGacha = PermissionName(rawValue: "loot-boxes-kompu-gacha")
    public static let lootBoxesPaidOpenLoop = PermissionName(rawValue: "loot-boxes-paid-open-loop")
    public static let sendGifts = PermissionName(rawValue: "send-gifts")
    public static let simulatedGambling = PermissionName(rawValue: "simulated-gambling")
    public static let virtualPropertyOwnership = PermissionName(rawValue: "virtual-property-ownership")
    public static let cameraAccess = PermissionName(rawValue: "camera-access")
    public static let shareGameClipsScreenshots = PermissionName(rawValue: "share-game-clips-screenshots")
    public static let photoVideoSharing = PermissionName(rawValue: "photo-video-sharing")
    public static let realTimeLocationSharing = PermissionName(rawValue: "real-time-location-sharing")
    public static let mods = PermissionName(rawValue: "mods")
    public static let gameplayStreaming = PermissionName(rawValue: "gameplay-streaming")
    public static let gameplayRecording = PermissionName(rawValue: "gameplay-recording")
    public static let linkToThirdPartyStreamingApp = PermissionName(rawValue: "link-to-third-party-streaming-app")
    public static let aiChat = PermissionName(rawValue: "ai-chat")
    public static let aiVoiceMode = PermissionName(rawValue: "ai-voice-mode")
    public static let aiMemory = PermissionName(rawValue: "ai-memory")
    public static let aiMediaGeneration = PermissionName(rawValue: "ai-media-generation")
    public static let aiModelTraining = PermissionName(rawValue: "ai-model-training")
    public static let aiCompanionChatbot = PermissionName(rawValue: "ai-companion-chatbot")
    public static let aiMediaUpload = PermissionName(rawValue: "ai-media-upload")
    public static let augmentedReality = PermissionName(rawValue: "augmented-reality")
    public static let matureLanguage = PermissionName(rawValue: "mature-language")
    public static let motionData = PermissionName(rawValue: "motion-data")
    public static let restrictedAdvertisingContent = PermissionName(rawValue: "restricted-advertising-content")

    public static let allCases: [PermissionName] = [
        .multiplayer,
        .leaderboardAndRankings,
        .joinGroups,
        .publicProfile,
        .customAvatar,
        .customUsername,
        .textChatPrivate,
        .textChatPublic,
        .voiceChat,
        .videoChat,
        .onlineStatus,
        .publicFriendList,
        .sendAcceptFriendRequests,
        .linkToThirdPartyChat,
        .virtualEvents,
        .personalizedRecommendations,
        .targetedAds,
        .profiling,
        .pushNotifications,
        .shareToSocialMedia,
        .directMarketing,
        .forums,
        .inGamePurchases,
        .lootBoxesPaidCosmeticOnly,
        .lootBoxesPaidGameplayImpacting,
        .lootBoxesKompuGacha,
        .lootBoxesPaidOpenLoop,
        .sendGifts,
        .simulatedGambling,
        .virtualPropertyOwnership,
        .cameraAccess,
        .shareGameClipsScreenshots,
        .photoVideoSharing,
        .realTimeLocationSharing,
        .mods,
        .gameplayStreaming,
        .gameplayRecording,
        .linkToThirdPartyStreamingApp,
        .aiChat,
        .aiVoiceMode,
        .aiMemory,
        .aiMediaGeneration,
        .aiModelTraining,
        .aiCompanionChatbot,
        .aiMediaUpload,
        .augmentedReality,
        .matureLanguage,
        .motionData,
        .restrictedAdvertisingContent,
    ]
}

/// A country or subdivision code the jurisdiction picker offers.
public struct JurisdictionCode: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public var description: String { rawValue }
}

extension JurisdictionCode {
    public static let AD = JurisdictionCode(rawValue: "AD")
    public static let AE = JurisdictionCode(rawValue: "AE")
    public static let AF = JurisdictionCode(rawValue: "AF")
    public static let AG = JurisdictionCode(rawValue: "AG")
    public static let AI = JurisdictionCode(rawValue: "AI")
    public static let AL = JurisdictionCode(rawValue: "AL")
    public static let AM = JurisdictionCode(rawValue: "AM")
    public static let AO = JurisdictionCode(rawValue: "AO")
    public static let AQ = JurisdictionCode(rawValue: "AQ")
    public static let AR = JurisdictionCode(rawValue: "AR")
    public static let AS = JurisdictionCode(rawValue: "AS")
    public static let AT = JurisdictionCode(rawValue: "AT")
    public static let AU = JurisdictionCode(rawValue: "AU")
    public static let AW = JurisdictionCode(rawValue: "AW")
    public static let AX = JurisdictionCode(rawValue: "AX")
    public static let AZ = JurisdictionCode(rawValue: "AZ")
    public static let BA = JurisdictionCode(rawValue: "BA")
    public static let BB = JurisdictionCode(rawValue: "BB")
    public static let BD = JurisdictionCode(rawValue: "BD")
    public static let BE = JurisdictionCode(rawValue: "BE")
    public static let BF = JurisdictionCode(rawValue: "BF")
    public static let BG = JurisdictionCode(rawValue: "BG")
    public static let BH = JurisdictionCode(rawValue: "BH")
    public static let BI = JurisdictionCode(rawValue: "BI")
    public static let BJ = JurisdictionCode(rawValue: "BJ")
    public static let BL = JurisdictionCode(rawValue: "BL")
    public static let BM = JurisdictionCode(rawValue: "BM")
    public static let BN = JurisdictionCode(rawValue: "BN")
    public static let BO = JurisdictionCode(rawValue: "BO")
    public static let BQ = JurisdictionCode(rawValue: "BQ")
    public static let BR = JurisdictionCode(rawValue: "BR")
    public static let BS = JurisdictionCode(rawValue: "BS")
    public static let BT = JurisdictionCode(rawValue: "BT")
    public static let BV = JurisdictionCode(rawValue: "BV")
    public static let BW = JurisdictionCode(rawValue: "BW")
    public static let BY = JurisdictionCode(rawValue: "BY")
    public static let BZ = JurisdictionCode(rawValue: "BZ")
    public static let CA = JurisdictionCode(rawValue: "CA")
    public static let CC = JurisdictionCode(rawValue: "CC")
    public static let CD = JurisdictionCode(rawValue: "CD")
    public static let CF = JurisdictionCode(rawValue: "CF")
    public static let CG = JurisdictionCode(rawValue: "CG")
    public static let CH = JurisdictionCode(rawValue: "CH")
    public static let CI = JurisdictionCode(rawValue: "CI")
    public static let CK = JurisdictionCode(rawValue: "CK")
    public static let CL = JurisdictionCode(rawValue: "CL")
    public static let CM = JurisdictionCode(rawValue: "CM")
    public static let CN = JurisdictionCode(rawValue: "CN")
    public static let CO = JurisdictionCode(rawValue: "CO")
    public static let CR = JurisdictionCode(rawValue: "CR")
    public static let CU = JurisdictionCode(rawValue: "CU")
    public static let CV = JurisdictionCode(rawValue: "CV")
    public static let CW = JurisdictionCode(rawValue: "CW")
    public static let CX = JurisdictionCode(rawValue: "CX")
    public static let CY = JurisdictionCode(rawValue: "CY")
    public static let CZ = JurisdictionCode(rawValue: "CZ")
    public static let DE = JurisdictionCode(rawValue: "DE")
    public static let DJ = JurisdictionCode(rawValue: "DJ")
    public static let DK = JurisdictionCode(rawValue: "DK")
    public static let DM = JurisdictionCode(rawValue: "DM")
    public static let DO = JurisdictionCode(rawValue: "DO")
    public static let DZ = JurisdictionCode(rawValue: "DZ")
    public static let EC = JurisdictionCode(rawValue: "EC")
    public static let EE = JurisdictionCode(rawValue: "EE")
    public static let EG = JurisdictionCode(rawValue: "EG")
    public static let EH = JurisdictionCode(rawValue: "EH")
    public static let ER = JurisdictionCode(rawValue: "ER")
    public static let ES = JurisdictionCode(rawValue: "ES")
    public static let ET = JurisdictionCode(rawValue: "ET")
    public static let FI = JurisdictionCode(rawValue: "FI")
    public static let FJ = JurisdictionCode(rawValue: "FJ")
    public static let FK = JurisdictionCode(rawValue: "FK")
    public static let FM = JurisdictionCode(rawValue: "FM")
    public static let FO = JurisdictionCode(rawValue: "FO")
    public static let FR = JurisdictionCode(rawValue: "FR")
    public static let GA = JurisdictionCode(rawValue: "GA")
    public static let GB = JurisdictionCode(rawValue: "GB")
    public static let GD = JurisdictionCode(rawValue: "GD")
    public static let GE = JurisdictionCode(rawValue: "GE")
    public static let GF = JurisdictionCode(rawValue: "GF")
    public static let GG = JurisdictionCode(rawValue: "GG")
    public static let GH = JurisdictionCode(rawValue: "GH")
    public static let GI = JurisdictionCode(rawValue: "GI")
    public static let GL = JurisdictionCode(rawValue: "GL")
    public static let GM = JurisdictionCode(rawValue: "GM")
    public static let GN = JurisdictionCode(rawValue: "GN")
    public static let GP = JurisdictionCode(rawValue: "GP")
    public static let GQ = JurisdictionCode(rawValue: "GQ")
    public static let GR = JurisdictionCode(rawValue: "GR")
    public static let GS = JurisdictionCode(rawValue: "GS")
    public static let GT = JurisdictionCode(rawValue: "GT")
    public static let GU = JurisdictionCode(rawValue: "GU")
    public static let GW = JurisdictionCode(rawValue: "GW")
    public static let GY = JurisdictionCode(rawValue: "GY")
    public static let HK = JurisdictionCode(rawValue: "HK")
    public static let HM = JurisdictionCode(rawValue: "HM")
    public static let HN = JurisdictionCode(rawValue: "HN")
    public static let HR = JurisdictionCode(rawValue: "HR")
    public static let HT = JurisdictionCode(rawValue: "HT")
    public static let HU = JurisdictionCode(rawValue: "HU")
    public static let ID = JurisdictionCode(rawValue: "ID")
    public static let IE = JurisdictionCode(rawValue: "IE")
    public static let IL = JurisdictionCode(rawValue: "IL")
    public static let IM = JurisdictionCode(rawValue: "IM")
    public static let IN = JurisdictionCode(rawValue: "IN")
    public static let IO = JurisdictionCode(rawValue: "IO")
    public static let IQ = JurisdictionCode(rawValue: "IQ")
    public static let IR = JurisdictionCode(rawValue: "IR")
    public static let IS = JurisdictionCode(rawValue: "IS")
    public static let IT = JurisdictionCode(rawValue: "IT")
    public static let JE = JurisdictionCode(rawValue: "JE")
    public static let JM = JurisdictionCode(rawValue: "JM")
    public static let JO = JurisdictionCode(rawValue: "JO")
    public static let JP = JurisdictionCode(rawValue: "JP")
    public static let KE = JurisdictionCode(rawValue: "KE")
    public static let KG = JurisdictionCode(rawValue: "KG")
    public static let KH = JurisdictionCode(rawValue: "KH")
    public static let KI = JurisdictionCode(rawValue: "KI")
    public static let KM = JurisdictionCode(rawValue: "KM")
    public static let KN = JurisdictionCode(rawValue: "KN")
    public static let KP = JurisdictionCode(rawValue: "KP")
    public static let KR = JurisdictionCode(rawValue: "KR")
    public static let KW = JurisdictionCode(rawValue: "KW")
    public static let KY = JurisdictionCode(rawValue: "KY")
    public static let KZ = JurisdictionCode(rawValue: "KZ")
    public static let LA = JurisdictionCode(rawValue: "LA")
    public static let LB = JurisdictionCode(rawValue: "LB")
    public static let LC = JurisdictionCode(rawValue: "LC")
    public static let LI = JurisdictionCode(rawValue: "LI")
    public static let LK = JurisdictionCode(rawValue: "LK")
    public static let LR = JurisdictionCode(rawValue: "LR")
    public static let LS = JurisdictionCode(rawValue: "LS")
    public static let LT = JurisdictionCode(rawValue: "LT")
    public static let LU = JurisdictionCode(rawValue: "LU")
    public static let LV = JurisdictionCode(rawValue: "LV")
    public static let LY = JurisdictionCode(rawValue: "LY")
    public static let MA = JurisdictionCode(rawValue: "MA")
    public static let MC = JurisdictionCode(rawValue: "MC")
    public static let MD = JurisdictionCode(rawValue: "MD")
    public static let ME = JurisdictionCode(rawValue: "ME")
    public static let MF = JurisdictionCode(rawValue: "MF")
    public static let MG = JurisdictionCode(rawValue: "MG")
    public static let MH = JurisdictionCode(rawValue: "MH")
    public static let MK = JurisdictionCode(rawValue: "MK")
    public static let ML = JurisdictionCode(rawValue: "ML")
    public static let MM = JurisdictionCode(rawValue: "MM")
    public static let MN = JurisdictionCode(rawValue: "MN")
    public static let MO = JurisdictionCode(rawValue: "MO")
    public static let MP = JurisdictionCode(rawValue: "MP")
    public static let MQ = JurisdictionCode(rawValue: "MQ")
    public static let MR = JurisdictionCode(rawValue: "MR")
    public static let MS = JurisdictionCode(rawValue: "MS")
    public static let MT = JurisdictionCode(rawValue: "MT")
    public static let MU = JurisdictionCode(rawValue: "MU")
    public static let MV = JurisdictionCode(rawValue: "MV")
    public static let MW = JurisdictionCode(rawValue: "MW")
    public static let MX = JurisdictionCode(rawValue: "MX")
    public static let MY = JurisdictionCode(rawValue: "MY")
    public static let MZ = JurisdictionCode(rawValue: "MZ")
    public static let NA = JurisdictionCode(rawValue: "NA")
    public static let NC = JurisdictionCode(rawValue: "NC")
    public static let NE = JurisdictionCode(rawValue: "NE")
    public static let NF = JurisdictionCode(rawValue: "NF")
    public static let NG = JurisdictionCode(rawValue: "NG")
    public static let NI = JurisdictionCode(rawValue: "NI")
    public static let NL = JurisdictionCode(rawValue: "NL")
    public static let NO = JurisdictionCode(rawValue: "NO")
    public static let NP = JurisdictionCode(rawValue: "NP")
    public static let NR = JurisdictionCode(rawValue: "NR")
    public static let NU = JurisdictionCode(rawValue: "NU")
    public static let NZ = JurisdictionCode(rawValue: "NZ")
    public static let OM = JurisdictionCode(rawValue: "OM")
    public static let PA = JurisdictionCode(rawValue: "PA")
    public static let PE = JurisdictionCode(rawValue: "PE")
    public static let PF = JurisdictionCode(rawValue: "PF")
    public static let PG = JurisdictionCode(rawValue: "PG")
    public static let PH = JurisdictionCode(rawValue: "PH")
    public static let PK = JurisdictionCode(rawValue: "PK")
    public static let PL = JurisdictionCode(rawValue: "PL")
    public static let PM = JurisdictionCode(rawValue: "PM")
    public static let PN = JurisdictionCode(rawValue: "PN")
    public static let PR = JurisdictionCode(rawValue: "PR")
    public static let PS = JurisdictionCode(rawValue: "PS")
    public static let PT = JurisdictionCode(rawValue: "PT")
    public static let PW = JurisdictionCode(rawValue: "PW")
    public static let PY = JurisdictionCode(rawValue: "PY")
    public static let QA = JurisdictionCode(rawValue: "QA")
    public static let RE = JurisdictionCode(rawValue: "RE")
    public static let RO = JurisdictionCode(rawValue: "RO")
    public static let RS = JurisdictionCode(rawValue: "RS")
    public static let RU = JurisdictionCode(rawValue: "RU")
    public static let RW = JurisdictionCode(rawValue: "RW")
    public static let SA = JurisdictionCode(rawValue: "SA")
    public static let SB = JurisdictionCode(rawValue: "SB")
    public static let SC = JurisdictionCode(rawValue: "SC")
    public static let SD = JurisdictionCode(rawValue: "SD")
    public static let SE = JurisdictionCode(rawValue: "SE")
    public static let SG = JurisdictionCode(rawValue: "SG")
    public static let SH = JurisdictionCode(rawValue: "SH")
    public static let SI = JurisdictionCode(rawValue: "SI")
    public static let SJ = JurisdictionCode(rawValue: "SJ")
    public static let SK = JurisdictionCode(rawValue: "SK")
    public static let SL = JurisdictionCode(rawValue: "SL")
    public static let SM = JurisdictionCode(rawValue: "SM")
    public static let SN = JurisdictionCode(rawValue: "SN")
    public static let SO = JurisdictionCode(rawValue: "SO")
    public static let SR = JurisdictionCode(rawValue: "SR")
    public static let SS = JurisdictionCode(rawValue: "SS")
    public static let ST = JurisdictionCode(rawValue: "ST")
    public static let SV = JurisdictionCode(rawValue: "SV")
    public static let SX = JurisdictionCode(rawValue: "SX")
    public static let SY = JurisdictionCode(rawValue: "SY")
    public static let SZ = JurisdictionCode(rawValue: "SZ")
    public static let TC = JurisdictionCode(rawValue: "TC")
    public static let TD = JurisdictionCode(rawValue: "TD")
    public static let TF = JurisdictionCode(rawValue: "TF")
    public static let TG = JurisdictionCode(rawValue: "TG")
    public static let TH = JurisdictionCode(rawValue: "TH")
    public static let TJ = JurisdictionCode(rawValue: "TJ")
    public static let TK = JurisdictionCode(rawValue: "TK")
    public static let TL = JurisdictionCode(rawValue: "TL")
    public static let TM = JurisdictionCode(rawValue: "TM")
    public static let TN = JurisdictionCode(rawValue: "TN")
    public static let TO = JurisdictionCode(rawValue: "TO")
    public static let TR = JurisdictionCode(rawValue: "TR")
    public static let TT = JurisdictionCode(rawValue: "TT")
    public static let TV = JurisdictionCode(rawValue: "TV")
    public static let TW = JurisdictionCode(rawValue: "TW")
    public static let TZ = JurisdictionCode(rawValue: "TZ")
    public static let UA = JurisdictionCode(rawValue: "UA")
    public static let UG = JurisdictionCode(rawValue: "UG")
    public static let UM = JurisdictionCode(rawValue: "UM")
    public static let US = JurisdictionCode(rawValue: "US")
    public static let UY = JurisdictionCode(rawValue: "UY")
    public static let UZ = JurisdictionCode(rawValue: "UZ")
    public static let VA = JurisdictionCode(rawValue: "VA")
    public static let VC = JurisdictionCode(rawValue: "VC")
    public static let VE = JurisdictionCode(rawValue: "VE")
    public static let VG = JurisdictionCode(rawValue: "VG")
    public static let VI = JurisdictionCode(rawValue: "VI")
    public static let VN = JurisdictionCode(rawValue: "VN")
    public static let VU = JurisdictionCode(rawValue: "VU")
    public static let WF = JurisdictionCode(rawValue: "WF")
    public static let WS = JurisdictionCode(rawValue: "WS")
    public static let YE = JurisdictionCode(rawValue: "YE")
    public static let YT = JurisdictionCode(rawValue: "YT")
    public static let ZA = JurisdictionCode(rawValue: "ZA")
    public static let ZM = JurisdictionCode(rawValue: "ZM")
    public static let ZW = JurisdictionCode(rawValue: "ZW")
    public static let AU_ACT = JurisdictionCode(rawValue: "AU-ACT")
    public static let AU_NSW = JurisdictionCode(rawValue: "AU-NSW")
    public static let AU_NT = JurisdictionCode(rawValue: "AU-NT")
    public static let AU_QLD = JurisdictionCode(rawValue: "AU-QLD")
    public static let AU_SA = JurisdictionCode(rawValue: "AU-SA")
    public static let AU_TAS = JurisdictionCode(rawValue: "AU-TAS")
    public static let AU_VIC = JurisdictionCode(rawValue: "AU-VIC")
    public static let AU_WA = JurisdictionCode(rawValue: "AU-WA")
    public static let CA_AB = JurisdictionCode(rawValue: "CA-AB")
    public static let CA_BC = JurisdictionCode(rawValue: "CA-BC")
    public static let CA_MB = JurisdictionCode(rawValue: "CA-MB")
    public static let CA_NB = JurisdictionCode(rawValue: "CA-NB")
    public static let CA_NS = JurisdictionCode(rawValue: "CA-NS")
    public static let CA_ON = JurisdictionCode(rawValue: "CA-ON")
    public static let CA_QC = JurisdictionCode(rawValue: "CA-QC")
    public static let CA_SK = JurisdictionCode(rawValue: "CA-SK")
    public static let PS_GZA = JurisdictionCode(rawValue: "PS-GZA")
    public static let PS_WBK = JurisdictionCode(rawValue: "PS-WBK")
    public static let AE_AZ = JurisdictionCode(rawValue: "AE-AZ")
    public static let AE_AJ = JurisdictionCode(rawValue: "AE-AJ")
    public static let AE_DU = JurisdictionCode(rawValue: "AE-DU")
    public static let AE_FU = JurisdictionCode(rawValue: "AE-FU")
    public static let AE_RK = JurisdictionCode(rawValue: "AE-RK")
    public static let AE_SH = JurisdictionCode(rawValue: "AE-SH")
    public static let AE_UQ = JurisdictionCode(rawValue: "AE-UQ")
    public static let GB_SCT = JurisdictionCode(rawValue: "GB-SCT")
    public static let US_AL = JurisdictionCode(rawValue: "US-AL")
    public static let US_AK = JurisdictionCode(rawValue: "US-AK")
    public static let US_AS = JurisdictionCode(rawValue: "US-AS")
    public static let US_AZ = JurisdictionCode(rawValue: "US-AZ")
    public static let US_AR = JurisdictionCode(rawValue: "US-AR")
    public static let US_CA = JurisdictionCode(rawValue: "US-CA")
    public static let US_CO = JurisdictionCode(rawValue: "US-CO")
    public static let US_CT = JurisdictionCode(rawValue: "US-CT")
    public static let US_DE = JurisdictionCode(rawValue: "US-DE")
    public static let US_DC = JurisdictionCode(rawValue: "US-DC")
    public static let US_FL = JurisdictionCode(rawValue: "US-FL")
    public static let US_GA = JurisdictionCode(rawValue: "US-GA")
    public static let US_GU = JurisdictionCode(rawValue: "US-GU")
    public static let US_HI = JurisdictionCode(rawValue: "US-HI")
    public static let US_ID = JurisdictionCode(rawValue: "US-ID")
    public static let US_IL = JurisdictionCode(rawValue: "US-IL")
    public static let US_IN = JurisdictionCode(rawValue: "US-IN")
    public static let US_IA = JurisdictionCode(rawValue: "US-IA")
    public static let US_KS = JurisdictionCode(rawValue: "US-KS")
    public static let US_KY = JurisdictionCode(rawValue: "US-KY")
    public static let US_LA = JurisdictionCode(rawValue: "US-LA")
    public static let US_ME = JurisdictionCode(rawValue: "US-ME")
    public static let US_MD = JurisdictionCode(rawValue: "US-MD")
    public static let US_MA = JurisdictionCode(rawValue: "US-MA")
    public static let US_MI = JurisdictionCode(rawValue: "US-MI")
    public static let US_MN = JurisdictionCode(rawValue: "US-MN")
    public static let US_MS = JurisdictionCode(rawValue: "US-MS")
    public static let US_MO = JurisdictionCode(rawValue: "US-MO")
    public static let US_MT = JurisdictionCode(rawValue: "US-MT")
    public static let US_NE = JurisdictionCode(rawValue: "US-NE")
    public static let US_NV = JurisdictionCode(rawValue: "US-NV")
    public static let US_NH = JurisdictionCode(rawValue: "US-NH")
    public static let US_NJ = JurisdictionCode(rawValue: "US-NJ")
    public static let US_NM = JurisdictionCode(rawValue: "US-NM")
    public static let US_NY = JurisdictionCode(rawValue: "US-NY")
    public static let US_NC = JurisdictionCode(rawValue: "US-NC")
    public static let US_ND = JurisdictionCode(rawValue: "US-ND")
    public static let US_MP = JurisdictionCode(rawValue: "US-MP")
    public static let US_OH = JurisdictionCode(rawValue: "US-OH")
    public static let US_OK = JurisdictionCode(rawValue: "US-OK")
    public static let US_OR = JurisdictionCode(rawValue: "US-OR")
    public static let US_PA = JurisdictionCode(rawValue: "US-PA")
    public static let US_PR = JurisdictionCode(rawValue: "US-PR")
    public static let US_RI = JurisdictionCode(rawValue: "US-RI")
    public static let US_SC = JurisdictionCode(rawValue: "US-SC")
    public static let US_SD = JurisdictionCode(rawValue: "US-SD")
    public static let US_TN = JurisdictionCode(rawValue: "US-TN")
    public static let US_TX = JurisdictionCode(rawValue: "US-TX")
    public static let US_UT = JurisdictionCode(rawValue: "US-UT")
    public static let US_VT = JurisdictionCode(rawValue: "US-VT")
    public static let US_VI = JurisdictionCode(rawValue: "US-VI")
    public static let US_VA = JurisdictionCode(rawValue: "US-VA")
    public static let US_WA = JurisdictionCode(rawValue: "US-WA")
    public static let US_WV = JurisdictionCode(rawValue: "US-WV")
    public static let US_WI = JurisdictionCode(rawValue: "US-WI")
    public static let US_WY = JurisdictionCode(rawValue: "US-WY")

    public static let allCases: [JurisdictionCode] = [
        .AD,
        .AE,
        .AF,
        .AG,
        .AI,
        .AL,
        .AM,
        .AO,
        .AQ,
        .AR,
        .AS,
        .AT,
        .AU,
        .AW,
        .AX,
        .AZ,
        .BA,
        .BB,
        .BD,
        .BE,
        .BF,
        .BG,
        .BH,
        .BI,
        .BJ,
        .BL,
        .BM,
        .BN,
        .BO,
        .BQ,
        .BR,
        .BS,
        .BT,
        .BV,
        .BW,
        .BY,
        .BZ,
        .CA,
        .CC,
        .CD,
        .CF,
        .CG,
        .CH,
        .CI,
        .CK,
        .CL,
        .CM,
        .CN,
        .CO,
        .CR,
        .CU,
        .CV,
        .CW,
        .CX,
        .CY,
        .CZ,
        .DE,
        .DJ,
        .DK,
        .DM,
        .DO,
        .DZ,
        .EC,
        .EE,
        .EG,
        .EH,
        .ER,
        .ES,
        .ET,
        .FI,
        .FJ,
        .FK,
        .FM,
        .FO,
        .FR,
        .GA,
        .GB,
        .GD,
        .GE,
        .GF,
        .GG,
        .GH,
        .GI,
        .GL,
        .GM,
        .GN,
        .GP,
        .GQ,
        .GR,
        .GS,
        .GT,
        .GU,
        .GW,
        .GY,
        .HK,
        .HM,
        .HN,
        .HR,
        .HT,
        .HU,
        .ID,
        .IE,
        .IL,
        .IM,
        .IN,
        .IO,
        .IQ,
        .IR,
        .IS,
        .IT,
        .JE,
        .JM,
        .JO,
        .JP,
        .KE,
        .KG,
        .KH,
        .KI,
        .KM,
        .KN,
        .KP,
        .KR,
        .KW,
        .KY,
        .KZ,
        .LA,
        .LB,
        .LC,
        .LI,
        .LK,
        .LR,
        .LS,
        .LT,
        .LU,
        .LV,
        .LY,
        .MA,
        .MC,
        .MD,
        .ME,
        .MF,
        .MG,
        .MH,
        .MK,
        .ML,
        .MM,
        .MN,
        .MO,
        .MP,
        .MQ,
        .MR,
        .MS,
        .MT,
        .MU,
        .MV,
        .MW,
        .MX,
        .MY,
        .MZ,
        .NA,
        .NC,
        .NE,
        .NF,
        .NG,
        .NI,
        .NL,
        .NO,
        .NP,
        .NR,
        .NU,
        .NZ,
        .OM,
        .PA,
        .PE,
        .PF,
        .PG,
        .PH,
        .PK,
        .PL,
        .PM,
        .PN,
        .PR,
        .PS,
        .PT,
        .PW,
        .PY,
        .QA,
        .RE,
        .RO,
        .RS,
        .RU,
        .RW,
        .SA,
        .SB,
        .SC,
        .SD,
        .SE,
        .SG,
        .SH,
        .SI,
        .SJ,
        .SK,
        .SL,
        .SM,
        .SN,
        .SO,
        .SR,
        .SS,
        .ST,
        .SV,
        .SX,
        .SY,
        .SZ,
        .TC,
        .TD,
        .TF,
        .TG,
        .TH,
        .TJ,
        .TK,
        .TL,
        .TM,
        .TN,
        .TO,
        .TR,
        .TT,
        .TV,
        .TW,
        .TZ,
        .UA,
        .UG,
        .UM,
        .US,
        .UY,
        .UZ,
        .VA,
        .VC,
        .VE,
        .VG,
        .VI,
        .VN,
        .VU,
        .WF,
        .WS,
        .YE,
        .YT,
        .ZA,
        .ZM,
        .ZW,
        .AU_ACT,
        .AU_NSW,
        .AU_NT,
        .AU_QLD,
        .AU_SA,
        .AU_TAS,
        .AU_VIC,
        .AU_WA,
        .CA_AB,
        .CA_BC,
        .CA_MB,
        .CA_NB,
        .CA_NS,
        .CA_ON,
        .CA_QC,
        .CA_SK,
        .PS_GZA,
        .PS_WBK,
        .AE_AZ,
        .AE_AJ,
        .AE_DU,
        .AE_FU,
        .AE_RK,
        .AE_SH,
        .AE_UQ,
        .GB_SCT,
        .US_AL,
        .US_AK,
        .US_AS,
        .US_AZ,
        .US_AR,
        .US_CA,
        .US_CO,
        .US_CT,
        .US_DE,
        .US_DC,
        .US_FL,
        .US_GA,
        .US_GU,
        .US_HI,
        .US_ID,
        .US_IL,
        .US_IN,
        .US_IA,
        .US_KS,
        .US_KY,
        .US_LA,
        .US_ME,
        .US_MD,
        .US_MA,
        .US_MI,
        .US_MN,
        .US_MS,
        .US_MO,
        .US_MT,
        .US_NE,
        .US_NV,
        .US_NH,
        .US_NJ,
        .US_NM,
        .US_NY,
        .US_NC,
        .US_ND,
        .US_MP,
        .US_OH,
        .US_OK,
        .US_OR,
        .US_PA,
        .US_PR,
        .US_RI,
        .US_SC,
        .US_SD,
        .US_TN,
        .US_TX,
        .US_UT,
        .US_VT,
        .US_VI,
        .US_VA,
        .US_WA,
        .US_WV,
        .US_WI,
        .US_WY,
    ]
}

/// The English country names the jurisdiction picker starts from.
package let COUNTRIES: [JurisdictionOption] = [
    .init(code: "AD", name: "Andorra"),
    .init(code: "AE", name: "United Arab Emirates"),
    .init(code: "AF", name: "Afghanistan"),
    .init(code: "AG", name: "Antigua and Barbuda"),
    .init(code: "AI", name: "Anguilla"),
    .init(code: "AL", name: "Albania"),
    .init(code: "AM", name: "Armenia"),
    .init(code: "AO", name: "Angola"),
    .init(code: "AQ", name: "Antarctica"),
    .init(code: "AR", name: "Argentina"),
    .init(code: "AS", name: "American Samoa"),
    .init(code: "AT", name: "Austria"),
    .init(code: "AU", name: "Australia"),
    .init(code: "AW", name: "Aruba"),
    .init(code: "AX", name: "Aland Islands"),
    .init(code: "AZ", name: "Azerbaijan"),
    .init(code: "BA", name: "Bosnia and Herzegovina"),
    .init(code: "BB", name: "Barbados"),
    .init(code: "BD", name: "Bangladesh"),
    .init(code: "BE", name: "Belgium"),
    .init(code: "BF", name: "Burkina Faso"),
    .init(code: "BG", name: "Bulgaria"),
    .init(code: "BH", name: "Bahrain"),
    .init(code: "BI", name: "Burundi"),
    .init(code: "BJ", name: "Benin"),
    .init(code: "BL", name: "Saint Barthelemy"),
    .init(code: "BM", name: "Bermuda"),
    .init(code: "BN", name: "Brunei Darussalam"),
    .init(code: "BO", name: "Bolivia"),
    .init(code: "BQ", name: "Bonaire, Sint Eustatius and Saba"),
    .init(code: "BR", name: "Brazil"),
    .init(code: "BS", name: "Bahamas"),
    .init(code: "BT", name: "Bhutan"),
    .init(code: "BV", name: "Bouvet Island"),
    .init(code: "BW", name: "Botswana"),
    .init(code: "BY", name: "Belarus"),
    .init(code: "BZ", name: "Belize"),
    .init(code: "CA", name: "Canada"),
    .init(code: "CC", name: "Cocos (Keeling) Islands"),
    .init(code: "CD", name: "Congo (Democratic Republic)"),
    .init(code: "CF", name: "Central African Republic"),
    .init(code: "CG", name: "Congo"),
    .init(code: "CH", name: "Switzerland"),
    .init(code: "CI", name: "Cote d'Ivoire"),
    .init(code: "CK", name: "Cook Islands"),
    .init(code: "CL", name: "Chile"),
    .init(code: "CM", name: "Cameroon"),
    .init(code: "CN", name: "China"),
    .init(code: "CO", name: "Colombia"),
    .init(code: "CR", name: "Costa Rica"),
    .init(code: "CU", name: "Cuba"),
    .init(code: "CV", name: "Cabo Verde"),
    .init(code: "CW", name: "Curacao"),
    .init(code: "CX", name: "Christmas Island"),
    .init(code: "CY", name: "Cyprus"),
    .init(code: "CZ", name: "Czechia"),
    .init(code: "DE", name: "Germany"),
    .init(code: "DJ", name: "Djibouti"),
    .init(code: "DK", name: "Denmark"),
    .init(code: "DM", name: "Dominica"),
    .init(code: "DO", name: "Dominican Republic"),
    .init(code: "DZ", name: "Algeria"),
    .init(code: "EC", name: "Ecuador"),
    .init(code: "EE", name: "Estonia"),
    .init(code: "EG", name: "Egypt"),
    .init(code: "EH", name: "Western Sahara"),
    .init(code: "ER", name: "Eritrea"),
    .init(code: "ES", name: "Spain"),
    .init(code: "ET", name: "Ethiopia"),
    .init(code: "FI", name: "Finland"),
    .init(code: "FJ", name: "Fiji"),
    .init(code: "FK", name: "Falkland Islands"),
    .init(code: "FM", name: "Micronesia"),
    .init(code: "FO", name: "Faroe Islands"),
    .init(code: "FR", name: "France"),
    .init(code: "GA", name: "Gabon"),
    .init(code: "GB", name: "United Kingdom"),
    .init(code: "GD", name: "Grenada"),
    .init(code: "GE", name: "Georgia"),
    .init(code: "GF", name: "French Guiana"),
    .init(code: "GG", name: "Guernsey"),
    .init(code: "GH", name: "Ghana"),
    .init(code: "GI", name: "Gibraltar"),
    .init(code: "GL", name: "Greenland"),
    .init(code: "GM", name: "Gambia"),
    .init(code: "GN", name: "Guinea"),
    .init(code: "GP", name: "Guadeloupe"),
    .init(code: "GQ", name: "Equatorial Guinea"),
    .init(code: "GR", name: "Greece"),
    .init(code: "GS", name: "South Georgia and the South Sandwich Islands"),
    .init(code: "GT", name: "Guatemala"),
    .init(code: "GU", name: "Guam"),
    .init(code: "GW", name: "Guinea-Bissau"),
    .init(code: "GY", name: "Guyana"),
    .init(code: "HK", name: "Hong Kong"),
    .init(code: "HM", name: "Heard Island and McDonald Islands"),
    .init(code: "HN", name: "Honduras"),
    .init(code: "HR", name: "Croatia"),
    .init(code: "HT", name: "Haiti"),
    .init(code: "HU", name: "Hungary"),
    .init(code: "ID", name: "Indonesia"),
    .init(code: "IE", name: "Ireland"),
    .init(code: "IL", name: "Israel"),
    .init(code: "IM", name: "Isle of Man"),
    .init(code: "IN", name: "India"),
    .init(code: "IO", name: "British Indian Ocean Territory"),
    .init(code: "IQ", name: "Iraq"),
    .init(code: "IR", name: "Iran"),
    .init(code: "IS", name: "Iceland"),
    .init(code: "IT", name: "Italy"),
    .init(code: "JE", name: "Jersey"),
    .init(code: "JM", name: "Jamaica"),
    .init(code: "JO", name: "Jordan"),
    .init(code: "JP", name: "Japan"),
    .init(code: "KE", name: "Kenya"),
    .init(code: "KG", name: "Kyrgyzstan"),
    .init(code: "KH", name: "Cambodia"),
    .init(code: "KI", name: "Kiribati"),
    .init(code: "KM", name: "Comoros"),
    .init(code: "KN", name: "Saint Kitts and Nevis"),
    .init(code: "KP", name: "Korea (Democratic People's Republic)"),
    .init(code: "KR", name: "Korea (Republic of)"),
    .init(code: "KW", name: "Kuwait"),
    .init(code: "KY", name: "Cayman Islands"),
    .init(code: "KZ", name: "Kazakhstan"),
    .init(code: "LA", name: "Lao People's Democratic Republic"),
    .init(code: "LB", name: "Lebanon"),
    .init(code: "LC", name: "Saint Lucia"),
    .init(code: "LI", name: "Liechtenstein"),
    .init(code: "LK", name: "Sri Lanka"),
    .init(code: "LR", name: "Liberia"),
    .init(code: "LS", name: "Lesotho"),
    .init(code: "LT", name: "Lithuania"),
    .init(code: "LU", name: "Luxembourg"),
    .init(code: "LV", name: "Latvia"),
    .init(code: "LY", name: "Libya"),
    .init(code: "MA", name: "Morocco"),
    .init(code: "MC", name: "Monaco"),
    .init(code: "MD", name: "Moldova"),
    .init(code: "ME", name: "Montenegro"),
    .init(code: "MF", name: "Saint Martin (French part)"),
    .init(code: "MG", name: "Madagascar"),
    .init(code: "MH", name: "Marshall Islands"),
    .init(code: "MK", name: "North Macedonia"),
    .init(code: "ML", name: "Mali"),
    .init(code: "MM", name: "Myanmar"),
    .init(code: "MN", name: "Mongolia"),
    .init(code: "MO", name: "Macao"),
    .init(code: "MP", name: "Northern Mariana Islands"),
    .init(code: "MQ", name: "Martinique"),
    .init(code: "MR", name: "Mauritania"),
    .init(code: "MS", name: "Montserrat"),
    .init(code: "MT", name: "Malta"),
    .init(code: "MU", name: "Mauritius"),
    .init(code: "MV", name: "Maldives"),
    .init(code: "MW", name: "Malawi"),
    .init(code: "MX", name: "Mexico"),
    .init(code: "MY", name: "Malaysia"),
    .init(code: "MZ", name: "Mozambique"),
    .init(code: "NA", name: "Namibia"),
    .init(code: "NC", name: "New Caledonia"),
    .init(code: "NE", name: "Niger"),
    .init(code: "NF", name: "Norfolk Island"),
    .init(code: "NG", name: "Nigeria"),
    .init(code: "NI", name: "Nicaragua"),
    .init(code: "NL", name: "Netherlands"),
    .init(code: "NO", name: "Norway"),
    .init(code: "NP", name: "Nepal"),
    .init(code: "NR", name: "Nauru"),
    .init(code: "NU", name: "Niue"),
    .init(code: "NZ", name: "New Zealand"),
    .init(code: "OM", name: "Oman"),
    .init(code: "PA", name: "Panama"),
    .init(code: "PE", name: "Peru"),
    .init(code: "PF", name: "French Polynesia"),
    .init(code: "PG", name: "Papua New Guinea"),
    .init(code: "PH", name: "Philippines"),
    .init(code: "PK", name: "Pakistan"),
    .init(code: "PL", name: "Poland"),
    .init(code: "PM", name: "Saint Pierre and Miquelon"),
    .init(code: "PN", name: "Pitcairn"),
    .init(code: "PR", name: "Puerto Rico"),
    .init(code: "PS", name: "Palestine"),
    .init(code: "PT", name: "Portugal"),
    .init(code: "PW", name: "Palau"),
    .init(code: "PY", name: "Paraguay"),
    .init(code: "QA", name: "Qatar"),
    .init(code: "RE", name: "Reunion"),
    .init(code: "RO", name: "Romania"),
    .init(code: "RS", name: "Serbia"),
    .init(code: "RU", name: "Russian Federation"),
    .init(code: "RW", name: "Rwanda"),
    .init(code: "SA", name: "Saudi Arabia"),
    .init(code: "SB", name: "Solomon Islands"),
    .init(code: "SC", name: "Seychelles"),
    .init(code: "SD", name: "Sudan"),
    .init(code: "SE", name: "Sweden"),
    .init(code: "SG", name: "Singapore"),
    .init(code: "SH", name: "Saint Helena, Ascension and Tristan da Cunha"),
    .init(code: "SI", name: "Slovenia"),
    .init(code: "SJ", name: "Svalbard and Jan Mayen"),
    .init(code: "SK", name: "Slovakia"),
    .init(code: "SL", name: "Sierra Leone"),
    .init(code: "SM", name: "San Marino"),
    .init(code: "SN", name: "Senegal"),
    .init(code: "SO", name: "Somalia"),
    .init(code: "SR", name: "Suriname"),
    .init(code: "SS", name: "South Sudan"),
    .init(code: "ST", name: "Sao Tome and Principe"),
    .init(code: "SV", name: "El Salvador"),
    .init(code: "SX", name: "Sint Maarten (Dutch part)"),
    .init(code: "SY", name: "Syrian Arab Republic"),
    .init(code: "SZ", name: "Eswatini"),
    .init(code: "TC", name: "Turks and Caicos Islands"),
    .init(code: "TD", name: "Chad"),
    .init(code: "TF", name: "French Southern Territories"),
    .init(code: "TG", name: "Togo"),
    .init(code: "TH", name: "Thailand"),
    .init(code: "TJ", name: "Tajikistan"),
    .init(code: "TK", name: "Tokelau"),
    .init(code: "TL", name: "Timor-Leste"),
    .init(code: "TM", name: "Turkmenistan"),
    .init(code: "TN", name: "Tunisia"),
    .init(code: "TO", name: "Tonga"),
    .init(code: "TR", name: "Turkiye"),
    .init(code: "TT", name: "Trinidad and Tobago"),
    .init(code: "TV", name: "Tuvalu"),
    .init(code: "TW", name: "Taiwan"),
    .init(code: "TZ", name: "Tanzania"),
    .init(code: "UA", name: "Ukraine"),
    .init(code: "UG", name: "Uganda"),
    .init(code: "UM", name: "United States Minor Outlying Islands"),
    .init(code: "US", name: "United States"),
    .init(code: "UY", name: "Uruguay"),
    .init(code: "UZ", name: "Uzbekistan"),
    .init(code: "VA", name: "Holy See"),
    .init(code: "VC", name: "Saint Vincent and the Grenadines"),
    .init(code: "VE", name: "Venezuela"),
    .init(code: "VG", name: "Virgin Islands (British)"),
    .init(code: "VI", name: "Virgin Islands (U.S.)"),
    .init(code: "VN", name: "Viet Nam"),
    .init(code: "VU", name: "Vanuatu"),
    .init(code: "WF", name: "Wallis and Futuna"),
    .init(code: "WS", name: "Samoa"),
    .init(code: "YE", name: "Yemen"),
    .init(code: "YT", name: "Mayotte"),
    .init(code: "ZA", name: "South Africa"),
    .init(code: "ZM", name: "Zambia"),
    .init(code: "ZW", name: "Zimbabwe"),
]
