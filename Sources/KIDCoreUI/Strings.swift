import Foundation

public struct KIDStrings: Equatable, Sendable {
    public struct Jurisdiction: Equatable, Sendable, Decodable {
        public var label: String
        public var placeholder: String
        public var submit: String
        /// `{country}` is the localized country, `{subdivision}` the region.
        public var subdivisionName: String
    }

    public struct Age: Equatable, Sendable, Decodable {
        public var dateOfBirthLabel: String
        /// `{age}` is the selected age.
        public var ageLabel: String
        public var submit: String
    }

    public struct AskAnAdult: Equatable, Sendable, Decodable {
        public var title: String
        public var description: String
        public var emailPlaceholder: String
        public var submit: String
        public var submitting: String
        public var error: String
        public var invalidEmail: String
    }

    public typealias VerifyAge = AskAnAdult

    public struct Settings: Equatable, Sendable, Decodable {
        public var title: String
        /// `{permission}` is the permission name.
        public var enabledLabel: String
        public var on: String
        public var off: String
        public var ask: String
        public var added: String
        public var granted: String
        public var askGrownup: String
        public var asking: String
        public var waiting: String
        /// Shown in place of `waiting` while the player's own age check is out.
        public var verifying: String
        public var error: String
    }

    public var jurisdiction: Jurisdiction
    public var age: Age
    public var askAnAdult: AskAnAdult
    public var verifyAge: VerifyAge
    public var settings: Settings
    public var subdivisions: [String: String]
    public var permissions: [String: KIDPermissionStrings]
}

public struct KIDPermissionStrings: Equatable, Sendable, Decodable {
    public var name: String

    public init(name: String) {
        self.name = name
    }
}

public struct KIDLocalization: Equatable, Sendable {
    public struct Jurisdiction: Equatable, Sendable, Decodable {
        public var label: String?
        public var placeholder: String?
        public var submit: String?
        public var subdivisionName: String?

        public init(
            label: String? = nil,
            placeholder: String? = nil,
            submit: String? = nil,
            subdivisionName: String? = nil
        ) {
            self.label = label
            self.placeholder = placeholder
            self.submit = submit
            self.subdivisionName = subdivisionName
        }
    }

    public struct Age: Equatable, Sendable, Decodable {
        public var dateOfBirthLabel: String?
        public var ageLabel: String?
        public var submit: String?

        public init(dateOfBirthLabel: String? = nil, ageLabel: String? = nil, submit: String? = nil) {
            self.dateOfBirthLabel = dateOfBirthLabel
            self.ageLabel = ageLabel
            self.submit = submit
        }
    }

    public struct AskAnAdult: Equatable, Sendable, Decodable {
        public var title: String?
        public var description: String?
        public var emailPlaceholder: String?
        public var submit: String?
        public var submitting: String?
        public var error: String?
        public var invalidEmail: String?

        public init(
            title: String? = nil,
            description: String? = nil,
            emailPlaceholder: String? = nil,
            submit: String? = nil,
            submitting: String? = nil,
            error: String? = nil,
            invalidEmail: String? = nil
        ) {
            self.title = title
            self.description = description
            self.emailPlaceholder = emailPlaceholder
            self.submit = submit
            self.submitting = submitting
            self.error = error
            self.invalidEmail = invalidEmail
        }
    }

    public typealias VerifyAge = AskAnAdult

    public struct Settings: Equatable, Sendable, Decodable {
        public var title: String?
        public var enabledLabel: String?
        public var on: String?
        public var off: String?
        public var ask: String?
        public var added: String?
        public var granted: String?
        public var askGrownup: String?
        public var asking: String?
        public var waiting: String?
        public var verifying: String?
        public var error: String?

        public init(
            title: String? = nil,
            enabledLabel: String? = nil,
            on: String? = nil,
            off: String? = nil,
            ask: String? = nil,
            added: String? = nil,
            granted: String? = nil,
            askGrownup: String? = nil,
            asking: String? = nil,
            waiting: String? = nil,
            verifying: String? = nil,
            error: String? = nil
        ) {
            self.title = title
            self.enabledLabel = enabledLabel
            self.on = on
            self.off = off
            self.ask = ask
            self.added = added
            self.granted = granted
            self.askGrownup = askGrownup
            self.asking = asking
            self.waiting = waiting
            self.verifying = verifying
            self.error = error
        }
    }

    public struct PermissionStrings: Equatable, Sendable, Decodable {
        public var name: String?

        public init(name: String? = nil) {
            self.name = name
        }
    }

    public var jurisdiction: Jurisdiction?
    public var age: Age?
    public var askAnAdult: AskAnAdult?
    public var verifyAge: VerifyAge?
    public var settings: Settings?
    public var subdivisions: [String: String]?
    public var permissions: [PermissionName: PermissionStrings]?
    public var locale: String?

    public init(
        jurisdiction: Jurisdiction? = nil,
        age: Age? = nil,
        askAnAdult: AskAnAdult? = nil,
        verifyAge: VerifyAge? = nil,
        settings: Settings? = nil,
        subdivisions: [String: String]? = nil,
        permissions: [PermissionName: PermissionStrings]? = nil,
        locale: String? = nil
    ) {
        self.jurisdiction = jurisdiction
        self.age = age
        self.askAnAdult = askAnAdult
        self.verifyAge = verifyAge
        self.settings = settings
        self.subdivisions = subdivisions
        self.permissions = permissions
        self.locale = locale
    }
}

private func mergeEmailStrings(_ s: inout KIDStrings.AskAnAdult, _ o: KIDLocalization.AskAnAdult) {
    s.title = o.title ?? s.title
    s.description = o.description ?? s.description
    s.emailPlaceholder = o.emailPlaceholder ?? s.emailPlaceholder
    s.submit = o.submit ?? s.submit
    s.submitting = o.submitting ?? s.submitting
    s.error = o.error ?? s.error
    s.invalidEmail = o.invalidEmail ?? s.invalidEmail
}

func mergeStrings(_ overrides: KIDLocalization?) -> KIDStrings {
    guard let overrides else { return DEFAULT_STRINGS }
    var s = DEFAULT_STRINGS
    if let o = overrides.jurisdiction {
        s.jurisdiction.label = o.label ?? s.jurisdiction.label
        s.jurisdiction.placeholder = o.placeholder ?? s.jurisdiction.placeholder
        s.jurisdiction.submit = o.submit ?? s.jurisdiction.submit
        s.jurisdiction.subdivisionName = o.subdivisionName ?? s.jurisdiction.subdivisionName
    }
    if let o = overrides.age {
        s.age.dateOfBirthLabel = o.dateOfBirthLabel ?? s.age.dateOfBirthLabel
        s.age.ageLabel = o.ageLabel ?? s.age.ageLabel
        s.age.submit = o.submit ?? s.age.submit
    }
    if let o = overrides.askAnAdult { mergeEmailStrings(&s.askAnAdult, o) }
    if let o = overrides.verifyAge { mergeEmailStrings(&s.verifyAge, o) }
    if let o = overrides.settings {
        s.settings.title = o.title ?? s.settings.title
        s.settings.enabledLabel = o.enabledLabel ?? s.settings.enabledLabel
        s.settings.on = o.on ?? s.settings.on
        s.settings.off = o.off ?? s.settings.off
        s.settings.ask = o.ask ?? s.settings.ask
        s.settings.added = o.added ?? s.settings.added
        s.settings.granted = o.granted ?? s.settings.granted
        s.settings.askGrownup = o.askGrownup ?? s.settings.askGrownup
        s.settings.asking = o.asking ?? s.settings.asking
        s.settings.waiting = o.waiting ?? s.settings.waiting
        s.settings.verifying = o.verifying ?? s.settings.verifying
        s.settings.error = o.error ?? s.settings.error
    }
    s.subdivisions.merge(overrides.subdivisions ?? [:]) { _, override in override }
    for (name, copy) in overrides.permissions ?? [:] {
        let base = s.permissions[name.rawValue] ?? KIDPermissionStrings(name: name.rawValue)
        s.permissions[name.rawValue] = KIDPermissionStrings(name: copy.name ?? base.name)
    }
    return s
}

func format(_ template: String, _ vars: [String: CustomStringConvertible]) -> String {
    let pattern = try! NSRegularExpression(pattern: #"\{(\w+)\}"#)
    let source = template as NSString
    var result = ""
    var cursor = 0
    for match in pattern.matches(in: template, range: NSRange(location: 0, length: source.length)) {
        result += source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
        let key = source.substring(with: match.range(at: 1))
        result += vars[key]?.description ?? source.substring(with: match.range)
        cursor = match.range.location + match.range.length
    }
    return result + source.substring(from: cursor)
}
