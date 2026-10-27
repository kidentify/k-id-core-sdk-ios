import Foundation
import SwiftUI

public enum KIDLocale: String, CaseIterable, Sendable {
    case ar, de, en
    case enGB = "en-GB"
    case es
    case esMX = "es-MX"
    case fr
    case frCA = "fr-CA"
    case hi, id, it, ja, ko, ms, nl, pt
    case ptBR = "pt-BR"
    case ru, th, tr, zh
    case zhHant = "zh-Hant"
}

public let KID_LOCALES: [KIDLocale] = KIDLocale.allCases

private struct LocaleFile: Decodable {
    var jurisdiction: KIDLocalization.Jurisdiction?
    var age: KIDLocalization.Age?
    var askAnAdult: KIDLocalization.AskAnAdult?
    var verifyAge: KIDLocalization.VerifyAge?
    var settings: KIDLocalization.Settings?
    var subdivisions: [String: String]?
}

private struct EnglishFile: Decodable {
    var jurisdiction: KIDStrings.Jurisdiction
    var age: KIDStrings.Age
    var askAnAdult: KIDStrings.AskAnAdult
    var verifyAge: KIDStrings.VerifyAge
    var settings: KIDStrings.Settings
    var subdivisions: [String: String]
}

func bundledLocalizationData(_ folder: String, _ locale: String) -> Data {
    guard
        let url = Bundle.module.url(
            forResource: locale, withExtension: "json", subdirectory: "localization/\(folder)"),
        let data = try? Data(contentsOf: url)
    else { preconditionFailure("KIDCore is missing its bundled \(folder)/\(locale).json") }
    return data
}

private func decodeBundled<T: Decodable>(_ type: T.Type, _ folder: String, _ locale: String) -> T {
    do {
        return try JSONDecoder().decode(type, from: bundledLocalizationData(folder, locale))
    } catch {
        preconditionFailure("KIDCore could not read its bundled \(folder)/\(locale).json: \(error)")
    }
}

public let DEFAULT_STRINGS: KIDStrings = {
    let en = decodeBundled(EnglishFile.self, "locales", KIDLocale.en.rawValue)
    return KIDStrings(
        jurisdiction: en.jurisdiction,
        age: en.age,
        askAnAdult: en.askAnAdult,
        verifyAge: en.verifyAge,
        settings: en.settings,
        subdivisions: en.subdivisions,
        permissions: decodeBundled([String: KIDPermissionStrings].self, "permissions", KIDLocale.en.rawValue)
    )
}()

private func bundledLocalization(_ locale: KIDLocale) -> KIDLocalization {
    let file = decodeBundled(LocaleFile.self, "locales", locale.rawValue)
    let permissions = decodeBundled([String: KIDLocalization.PermissionStrings].self, "permissions", locale.rawValue)
    return KIDLocalization(
        jurisdiction: file.jurisdiction,
        age: file.age,
        askAnAdult: file.askAnAdult,
        verifyAge: file.verifyAge,
        settings: file.settings,
        subdivisions: file.subdivisions,
        permissions: Dictionary(uniqueKeysWithValues: permissions.map { (PermissionName(rawValue: $0.key), $0.value) }),
        locale: locale.rawValue
    )
}

extension KIDLocalization {
    public static let arSA = bundledLocalization(.ar)
    public static let deDE = bundledLocalization(.de)
    public static let enGB = bundledLocalization(.enGB)
    public static let esES = bundledLocalization(.es)
    public static let esMX = bundledLocalization(.esMX)
    public static let frFR = bundledLocalization(.fr)
    public static let frCA = bundledLocalization(.frCA)
    public static let hiIN = bundledLocalization(.hi)
    public static let idID = bundledLocalization(.id)
    public static let itIT = bundledLocalization(.it)
    public static let jaJP = bundledLocalization(.ja)
    public static let koKR = bundledLocalization(.ko)
    public static let msMY = bundledLocalization(.ms)
    public static let nlNL = bundledLocalization(.nl)
    public static let ptPT = bundledLocalization(.pt)
    public static let ptBR = bundledLocalization(.ptBR)
    public static let ruRU = bundledLocalization(.ru)
    public static let thTH = bundledLocalization(.th)
    public static let trTR = bundledLocalization(.tr)
    public static let zhCN = bundledLocalization(.zh)
    public static let zhTW = bundledLocalization(.zhHant)
}

private let traditionalChineseSubtags: Set<String> = ["hant", "tw", "hk", "mo"]

private func resolveLocale(_ tag: String) -> KIDLocale {
    let lower = tag.replacingOccurrences(of: "_", with: "-").lowercased()
    let match = { (t: String) in KIDLocale.allCases.first { $0.rawValue.lowercased() == t } }
    if let exact = match(lower) { return exact }
    let parts = lower.split(separator: "-", omittingEmptySubsequences: false).map(String.init)
    let language = parts.first ?? ""
    if language == "zh" && parts.dropFirst().contains(where: traditionalChineseSubtags.contains) { return .zhHant }
    return match(language) ?? .en
}

/// Matches the exact tag first, then Traditional Chinese for `zh-TW`, `zh-HK`, `zh-MO` and `zh-Hant`, then the
/// base language, then English. English is `KIDLocalization(locale: "en")`, which keeps the built-in copy.
public func getKIDLocalization(_ locale: String) -> KIDLocalization {
    switch resolveLocale(locale) {
    case .ar: .arSA
    case .de: .deDE
    case .en: KIDLocalization(locale: "en")
    case .enGB: .enGB
    case .es: .esES
    case .esMX: .esMX
    case .fr: .frFR
    case .frCA: .frCA
    case .hi: .hiIN
    case .id: .idID
    case .it: .itIT
    case .ja: .jaJP
    case .ko: .koKR
    case .ms: .msMY
    case .nl: .nlNL
    case .pt: .ptPT
    case .ptBR: .ptBR
    case .ru: .ruRU
    case .th: .thTH
    case .tr: .trTR
    case .zh: .zhCN
    case .zhHant: .zhTW
    }
}

private let rtlLanguages: Set<String> = ["ar", "fa", "he", "ur"]

func textDirection(_ locale: String?) -> LayoutDirection? {
    guard let locale, !locale.isEmpty else { return nil }
    let language = locale.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map { $0.lowercased() } ?? ""
    return rtlLanguages.contains(language) ? .rightToLeft : .leftToRight
}
