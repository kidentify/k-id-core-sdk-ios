import SwiftUI

public enum KIDAgeMethod: String, Sendable {
    case dateOfBirth = "date-of-birth"
    case ageSlider = "age-slider"
}

private let defaultAgeMethodPreference: [KIDAgeMethod] = [.ageSlider, .dateOfBirth]

func matchingJurisdictions(_ options: [JurisdictionOption], _ query: String) -> [JurisdictionOption] {
    let q = query.trimmingCharacters(in: .whitespaces)
    guard !q.isEmpty else { return options }
    return options.filter { $0.name.localizedStandardContains(q) || $0.code.localizedCaseInsensitiveContains(q) }
}

private struct JurisdictionSheet: View {
    let title: String
    let options: [JurisdictionOption]
    let selected: String
    let onPick: (String) -> Void
    @State private var query = ""

    private var matches: [JurisdictionOption] { matchingJurisdictions(options, query) }

    var body: some View {
        NavigationView {
            List(matches) { option in
                Button {
                    onPick(option.code)
                } label: {
                    HStack {
                        Text(option.name).foregroundColor(.primary)
                        Spacer()
                        if option.code == selected { Image(systemName: "checkmark") }
                    }
                }
            }
            .searchable(text: $query)
            .navigationTitle(title)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(iOS)
            .navigationViewStyle(.stack)
        #endif
    }
}

let MAX_SLIDER_AGE = 35

func sliderAgeLabel(_ age: Int?) -> String {
    guard let age else { return "-" }
    return age == MAX_SLIDER_AGE ? "\(age)+" : String(age)
}

public struct KIDSelectJurisdiction: View {
    @EnvironmentObject private var core: KIDCoreContext
    @EnvironmentObject private var flow: AgeGateController
    @State private var code = ""
    @State private var picking = false
    private let onSelect: ((String) -> Void)?

    public init(onSelect: ((String) -> Void)? = nil) {
        self.onSelect = onSelect
    }

    public var body: some View {
        if flow.state.step == .jurisdiction {
            let t = core.strings.jurisdiction
            let a = core.appearance
            VStack(alignment: .leading, spacing: 12) {
                Text(t.label).kidElement(a, .label)
                Button {
                    picking = true
                } label: {
                    HStack {
                        Text(core.jurisdictions.first { $0.code == code }?.name ?? t.placeholder)
                            .foregroundColor(code.isEmpty ? a.variables.colorTextMuted : a.variables.colorText)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").foregroundColor(a.variables.colorTextMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .kidElement(a, .input)
                .accessibilityLabel(t.label)
                .sheet(isPresented: $picking) {
                    JurisdictionSheet(title: t.label, options: core.jurisdictions, selected: code) {
                        code = $0
                        picking = false
                    }
                }
                Button {
                    guard !code.isEmpty else { return }
                    flow.setJurisdiction(code)
                    onSelect?(code)
                } label: {
                    Text(t.submit).frame(maxWidth: .infinity).kidElement(a, .button)
                }
                .buttonStyle(.plain)
                .disabled(code.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .kidElement(a, .card, .selectJurisdiction)
        }
    }
}

public struct KIDCollectAge: View {
    @EnvironmentObject private var core: KIDCoreContext
    @EnvironmentObject private var flow: AgeGateController
    @State private var dob = Date()
    @State private var dobChosen = false
    @State private var dobOpen = false
    @State private var age: Int?
    private let methods: [KIDAgeMethod]?
    private let onSubmit: ((AgeSignal) -> Void)?

    public init(methods: [KIDAgeMethod]? = nil, onSubmit: ((AgeSignal) -> Void)? = nil) {
        self.methods = methods
        self.onSubmit = onSubmit
    }

    private var method: KIDAgeMethod? {
        guard let approved = flow.state.requirements?.approvedAgeCollectionMethods.compactMap(KIDAgeMethod.init) else {
            return nil
        }
        return (methods ?? defaultAgeMethodPreference).first(where: approved.contains) ?? approved.first
    }

    private func submit(_ method: KIDAgeMethod) {
        let signal: AgeSignal
        if method == .dateOfBirth {
            signal = .dateOfBirth(isoDay(dob))
        } else if let age {
            signal = .age(age)
        } else {
            return
        }
        flow.setAge(signal)
        onSubmit?(signal)
    }

    public var body: some View {
        if flow.state.step == .age, let method {
            let t = core.strings.age
            let a = core.appearance
            VStack(alignment: .leading, spacing: 12) {
                if method == .dateOfBirth {
                    Text(t.dateOfBirthLabel).kidElement(a, .label)
                    if dobOpen {
                        DatePicker(t.dateOfBirthLabel, selection: $dob, in: ...Date(), displayedComponents: .date)
                            .labelsHidden()
                            #if os(iOS)
                                .datePickerStyle(.wheel)
                            #endif
                            .tint(a.variables.colorPrimary)
                            .onChange(of: dob) { _ in dobChosen = true }
                            .frame(maxWidth: .infinity)
                    } else {
                        Button {
                            dobOpen = true
                        } label: {
                            HStack {
                                Text(dateFieldPlaceholder()).foregroundColor(a.variables.colorTextMuted)
                                Spacer()
                                Image(systemName: "calendar").foregroundColor(a.variables.colorTextMuted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .kidElement(a, .input)
                        .accessibilityLabel(t.dateOfBirthLabel)
                    }
                    Button {
                        submit(method)
                    } label: {
                        Text(t.submit).frame(maxWidth: .infinity).kidElement(a, .button)
                    }
                    .buttonStyle(.plain)
                    .disabled(!dobChosen)
                } else {
                    let label = format(t.ageLabel, ["age": sliderAgeLabel(age)])
                    Text(label).kidElement(a, .label)
                    Slider(
                        value: Binding(get: { Double(age ?? 1) }, set: { age = Int($0) }),
                        in: 1...Double(MAX_SLIDER_AGE),
                        step: 1,
                        onEditingChanged: { editing in if !editing && age == nil { age = 1 } }
                    )
                    .tint(a.variables.colorPrimary)
                    .accessibilityLabel(label)
                    .kidElement(a, .input)
                    Button {
                        submit(method)
                    } label: {
                        Text(t.submit).frame(maxWidth: .infinity).kidElement(a, .button)
                    }
                    .buttonStyle(.plain)
                    .disabled(age == nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .kidElement(a, .card, .collectAge)
        }
    }
}

private let emailPattern =
    #"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#

func isValidEmail(_ email: String) -> Bool {
    email.range(of: emailPattern, options: .regularExpression) != nil
}

func dateFieldPlaceholder(_ locale: Locale = .current) -> String {
    (DateFormatter.dateFormat(fromTemplate: "ddMMyyyy", options: 0, locale: locale) ?? "dd/MM/yyyy").lowercased()
}

func isoDay(_ date: Date, timeZone: TimeZone = .current) -> String {
    var gregorian = Calendar(identifier: .gregorian)
    gregorian.timeZone = timeZone
    let c = gregorian.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
}

struct ChallengeEmailForm: View {
    @EnvironmentObject private var core: KIDCoreContext
    @State private var email = ""
    @State private var busy = false
    @State private var error: String?
    let strings: (KIDStrings) -> KIDStrings.AskAnAdult
    let element: ElementName
    let setEmail: (String) -> Void
    let send: () async -> KIDResult
    let onSent: ((String) -> Void)?

    private func submit() async {
        let t = strings(core.strings)
        busy = true
        error = nil
        setEmail(email)
        let res = await send()
        if res.ok {
            onSent?(email)
        } else {
            error = res.error?.code == .invalidRequest ? t.invalidEmail : t.error
        }
        busy = false
    }

    var body: some View {
        let t = strings(core.strings)
        let a = core.appearance
        VStack(alignment: .leading, spacing: 12) {
            Text(t.title).kidElement(a, .label)
            Text(t.description).kidElement(a, .muted)
            emailField(t.emailPlaceholder).kidElement(a, .input)
            Button {
                Task { await submit() }
            } label: {
                Text(busy ? t.submitting : t.submit).frame(maxWidth: .infinity).kidElement(a, .button)
            }
            .buttonStyle(.plain)
            .disabled(busy || !isValidEmail(email))
            if let error {
                Text(error).kidElement(a, .danger)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidElement(a, .card, element)
    }

    @ViewBuilder
    private func emailField(_ placeholder: String) -> some View {
        #if os(iOS)
            TextField(placeholder, text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        #else
            TextField(placeholder, text: $email)
        #endif
    }
}

private struct GateEmailForm: View {
    @EnvironmentObject private var flow: AgeGateController
    let step: AgeGateStep
    let strings: (KIDStrings) -> KIDStrings.AskAnAdult
    let element: ElementName
    let onSent: ((String) -> Void)?

    var body: some View {
        if flow.state.step == step && !flow.state.emailProvided {
            ChallengeEmailForm(
                strings: strings,
                element: element,
                setEmail: flow.setEmail,
                send: { await flow.submit() },
                onSent: onSent
            )
        }
    }
}

public struct KIDAskAnAdult: View {
    private let onSent: ((String) -> Void)?

    /// - Parameter onSent: Called with the email once the request is sent.
    public init(onSent: ((String) -> Void)? = nil) {
        self.onSent = onSent
    }

    public var body: some View {
        GateEmailForm(step: .parentalConsent, strings: \.askAnAdult, element: .askAnAdult, onSent: onSent)
    }
}

public struct KIDVerifyAge: View {
    private let onSent: ((String) -> Void)?

    public init(onSent: ((String) -> Void)? = nil) {
        self.onSent = onSent
    }

    public var body: some View {
        GateEmailForm(step: .ageAssurance, strings: \.verifyAge, element: .verifyAge, onSent: onSent)
    }
}

public struct KIDSessionVerifyAgePending<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .pending }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDSessionVerifyAgeFail<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .fail }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDSessionVerifyAgePass<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .pass }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDSessionVerifyAgeError<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .error }
    public var slotView: AnyView { AnyView(content) }
}

/// Verifies the player is an adult (the civil age of their jurisdiction) on the established session: the email form
/// while it needs the player's email, then the slot matching the outcome. Renders nothing until the age gate passes.
/// Showing it again after a fail or error tries again.
public struct KIDSessionVerifyAge: View {
    @EnvironmentObject private var gate: AgeGateController
    private let onSent: ((String) -> Void)?
    private let slots: [any KIDAgeGateSlot]

    public init(onSent: ((String) -> Void)? = nil, @KIDAgeGateSlotBuilder slots: () -> [any KIDAgeGateSlot]) {
        self.onSent = onSent
        self.slots = slots()
    }

    public var body: some View {
        if let controller = gate.sessionVerifyAge() {
            SessionVerifyAgeBody(controller: controller, onSent: onSent, slots: slots).id(ObjectIdentifier(controller))
        }
    }
}

private struct SessionVerifyAgeBody: View {
    @ObservedObject var controller: VerifyAgeController
    let onSent: ((String) -> Void)?
    let slots: [any KIDAgeGateSlot]

    var body: some View {
        VStack(spacing: 0) {
            // Content that renders nothing never fires onAppear, and the flow renders nothing while it checks.
            Color.clear.frame(width: 0, height: 0).onAppear { controller.start() }
            if controller.state.status != .running {
                slots.last(where: { $0.slotStatus == controller.state.status })?.slotView
            } else if controller.state.step == .email {
                ChallengeEmailForm(
                    strings: \.verifyAge,
                    element: .verifyAge,
                    setEmail: controller.setEmail,
                    send: { await controller.submit() },
                    onSent: onSent
                )
            }
        }
    }
}

public struct KIDPermission<Content: View, Fallback: View>: View {
    @EnvironmentObject private var flow: AgeGateController
    private let name: PermissionName
    private let content: Content
    private let fallback: Fallback

    public init(_ name: PermissionName, @ViewBuilder content: () -> Content, @ViewBuilder fallback: () -> Fallback) {
        self.name = name
        self.content = content()
        self.fallback = fallback()
    }

    public var body: some View {
        if flow.permission.can(name) { content } else { fallback }
    }
}

extension KIDPermission where Fallback == EmptyView {
    public init(_ name: PermissionName, @ViewBuilder content: () -> Content) {
        self.init(name, content: content, fallback: { EmptyView() })
    }
}
