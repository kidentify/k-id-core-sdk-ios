import Foundation

extension JurisdictionCode: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public static let auto = JurisdictionCode(rawValue: "auto")
}

private let englishCountryNames = Dictionary(uniqueKeysWithValues: COUNTRIES.map { ($0.code, $0.name) })

private func validLocale(_ locale: String?) -> String? {
    guard let locale, locale.range(of: #"^[A-Za-z]{2,3}(-[A-Za-z0-9]{1,8})*$"#, options: .regularExpression) != nil
    else { return nil }
    let parts = locale.split(separator: "-").map(String.init)
    return ([parts[0].lowercased()] + parts.dropFirst().map { part in
        switch part.count {
        case 4 where part.allSatisfy(\.isLetter): part.prefix(1).uppercased() + part.dropFirst().lowercased()
        case 2 where part.allSatisfy(\.isLetter): part.uppercased()
        default: part.lowercased()
        }
    }).joined(separator: "-")
}

private func countryNamer(_ locale: String?) -> (String) -> String {
    let english = { (code: String) in englishCountryNames[code] ?? code }
    guard let locale, locale.split(separator: "-").first != "en" else { return english }
    let names = Locale(identifier: locale)
    return { code in names.localizedString(forRegionCode: code) ?? english(code) }
}

func localizeJurisdictions(_ strings: KIDStrings, _ locale: String? = nil) -> [JurisdictionOption] {
    let tag = validLocale(locale)
    let country = countryNamer(tag)
    let subdivisions = DEFAULT_STRINGS.subdivisions.keys.map { code in
        JurisdictionOption(
            code: code,
            name: format(
                strings.jurisdiction.subdivisionName,
                [
                    "country": country(String(code.prefix(2))),
                    "subdivision": strings.subdivisions[code] ?? DEFAULT_STRINGS.subdivisions[code] ?? code,
                ]
            )
        )
    }
    let collation = Locale(identifier: tag ?? "en")
    return (COUNTRIES.map { JurisdictionOption(code: $0.code, name: country($0.code)) } + subdivisions).sorted {
        $0.name.compare($1.name, locale: collation) == .orderedAscending
    }
}

public let JURISDICTIONS: [JurisdictionOption] = localizeJurisdictions(DEFAULT_STRINGS)
