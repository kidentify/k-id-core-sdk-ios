import SwiftUI

extension KIDStrings {
    func permissionName(_ name: String) -> String { permissions[name]?.name ?? name }
}

enum VerifyAgeStep: Equatable {
    case verify, email, sending
}

/// Where a Verify age row goes once its own request returns. A failure puts it back to its button with the error, so
/// the player starts over; without an email, `invalidRequest` is the age check asking for the player's email instead.
func verifyAgeStep(after res: KIDResult, sentEmail: Bool) -> (step: VerifyAgeStep, failed: KIDErrorCode?) {
    if res.ok { return (.verify, nil) }
    let code = res.error?.code ?? .unavailable
    if !sentEmail && code == .invalidRequest { return (.email, nil) }
    return (.verify, code)
}

/// The grownup form after its own ask: a failure stages the asked permissions again, with the error.
func grownupAskReset(after res: KIDResult, asked names: [PermissionName]) -> (staged: [PermissionName], failed: KIDErrorCode?) {
    res.ok ? ([], nil) : (names, res.error?.code ?? .unavailable)
}

private struct PlayerRow: View {
    @EnvironmentObject private var core: KIDCoreContext
    @EnvironmentObject private var settings: SettingsController
    let permission: Permission
    @State private var busy = false
    @State private var failed = false

    private func toggle(_ enabled: Bool) async {
        busy = true
        failed = false
        if !(await settings.change(permission.permissionName, enabled: enabled)).ok { failed = true }
        busy = false
    }

    var body: some View {
        let t = core.strings.settings
        let a = core.appearance
        let name = format(t.enabledLabel, ["permission": core.strings.permissionName(permission.name)])
        HStack(spacing: 12) {
            Text(name).kidElement(a, .label)
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Toggle(
                    isOn: Binding(get: { permission.enabled }, set: { value in Task { await toggle(value) } })
                ) {
                    Text(permission.enabled ? t.on : t.off).kidElement(a, .muted)
                }
                .fixedSize()
                .tint(a.variables.colorPrimary)
                .disabled(busy)
                .accessibilityLabel(name)
                if failed {
                    Text(t.error).kidElement(a, .danger)
                }
            }
            .kidElement(a, .controlColumn)
        }
        .kidElement(a, .row)
    }
}

private struct VerifyAgeRow: View {
    @EnvironmentObject private var core: KIDCoreContext
    @EnvironmentObject private var settings: SettingsController
    let permission: Permission
    let disabled: Bool
    @State private var step = VerifyAgeStep.verify
    @State private var failedCode: KIDErrorCode?
    @State private var email = ""

    private func request(email playerEmail: String?) async -> KIDResult {
        step = .sending
        failedCode = nil
        let res = await settings.upgrade([permission.permissionName], approverEmail: playerEmail)
        (step, failedCode) = verifyAgeStep(after: res, sentEmail: playerEmail != nil)
        return res
    }

    var body: some View {
        let strings = core.strings
        let t = strings.settings
        let a = core.appearance
        let name = format(t.enabledLabel, ["permission": strings.permissionName(permission.name)])
        let challenge = settings.permissionSettings.challenge
        let mine = challenge.challengeKind == .ageAssurance && challenge.permissions.contains(permission.permissionName)
        if step == .sending || (mine && challenge.status == .pending) {
            HStack(spacing: 12) {
                Text(name).kidElement(a, .label)
                Spacer()
                Text(step == .sending ? strings.verifyAge.submitting : t.verifying).kidElement(a, .muted)
            }
            .kidElement(a, .row)
        } else if step == .email {
            ChallengeEmailForm(
                strings: \.verifyAge,
                element: .verifyAge,
                setEmail: { email = $0 },
                send: { await request(email: email) },
                onSent: nil
            )
        } else {
            HStack(spacing: 12) {
                Text(name).kidElement(a, .label)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Button {
                        Task { _ = await request(email: nil) }
                    } label: {
                        Text(strings.verifyAge.title).kidElement(a, .pill, .pillAsk)
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                    .accessibilityLabel("\(strings.verifyAge.title) \(name)")
                    if let failedCode {
                        Text(failedCode == .invalidRequest ? strings.verifyAge.invalidEmail : strings.verifyAge.error)
                            .kidElement(a, .danger)
                    }
                }
                .kidElement(a, .controlColumn)
            }
            .kidElement(a, .row)
        }
    }
}

private struct GuardianRow: View {
    @EnvironmentObject private var core: KIDCoreContext
    let permission: Permission
    let added: Bool
    let disabled: Bool
    let onToggle: () -> Void

    var body: some View {
        let t = core.strings.settings
        let a = core.appearance
        let name = format(t.enabledLabel, ["permission": core.strings.permissionName(permission.name)])
        HStack(spacing: 12) {
            Text(name).kidElement(a, .label)
            Spacer()
            if permission.enabled {
                Text(t.granted).kidElement(a, .muted)
            } else {
                Button(action: onToggle) {
                    Text(added ? t.added : t.ask).kidElement(a, .pill, added ? .pillAdded : .pillAsk)
                }
                .buttonStyle(.plain)
                .disabled(disabled)
                .accessibilityLabel("\(added ? t.added : t.ask) \(name)")
            }
        }
        .kidElement(a, .row)
    }
}

public struct KIDPermissionSettings: View {
    @EnvironmentObject private var core: KIDCoreContext
    @EnvironmentObject private var settings: SettingsController
    @State private var staged: [PermissionName] = []
    @State private var approverEmail = ""
    @State private var failedCode: KIDErrorCode?
    // The ask this form sent itself, so a Verify age row's request never shows here.
    @State private var asking = false
    @State private var askFailed = false

    public init() {}

    private func reseed(_ challenge: SettingsChallengeState) {
        if challenge.status != .error { askFailed = false }
        if challenge.status == .error && challenge.challengeKind == .parentalConsent && staged.isEmpty {
            staged = challenge.permissions
        }
    }

    private func ask(hasApproverEmail: Bool) async {
        guard !staged.isEmpty else { return }
        let names = staged
        staged = []
        asking = true
        let res = await settings.upgrade(names, approverEmail: hasApproverEmail ? nil : approverEmail)
        asking = false
        let reset = grownupAskReset(after: res, asked: names)
        if !reset.staged.isEmpty { staged = reset.staged }
        failedCode = reset.failed
        askFailed = reset.failed != nil
    }

    public var body: some View {
        let strings = core.strings
        let t = strings.settings
        let a = core.appearance
        let s = settings.permissionSettings
        let inFlight = s.challenge.status == .sending || s.challenge.status == .pending
        let needsEmail = !s.hasApproverEmail && !inFlight
        let waiting = s.challenge.status == .pending && s.challenge.challengeKind != .ageAssurance
        let grownupFailed = askFailed || (s.challenge.status == .error && s.challenge.challengeKind == .parentalConsent)
        Group {
            if s.error != nil && !s.isLoaded {
                Text(t.error).kidElement(a, .danger)
            } else if s.isLoaded {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(s.permissions.filter { $0.managedBy != .prohibited }, id: \.name) { p in
                        let name = p.permissionName
                        if p.managedBy == .guardian {
                            GuardianRow(
                                permission: p,
                                added: inFlight ? s.challenge.permissions.contains(name) : staged.contains(name),
                                disabled: inFlight
                            ) {
                                staged = staged.contains(name) ? staged.filter { $0 != name } : staged + [name]
                            }
                        } else if p.verifiedAgeThreshold != nil && !p.enabled {
                            VerifyAgeRow(permission: p, disabled: inFlight || !staged.isEmpty)
                        } else {
                            PlayerRow(permission: p)
                        }
                    }
                    if !staged.isEmpty || asking || waiting {
                        VStack(alignment: .leading, spacing: 12) {
                            if needsEmail {
                                Text(strings.askAnAdult.title).kidElement(a, .label)
                                Text(strings.askAnAdult.description).kidElement(a, .muted)
                                emailField(strings.askAnAdult.emailPlaceholder).kidElement(a, .input)
                            }
                            Button {
                                Task { await ask(hasApproverEmail: s.hasApproverEmail) }
                            } label: {
                                Text(asking ? t.asking : waiting ? t.waiting : t.askGrownup)
                                .frame(maxWidth: .infinity)
                                .kidElement(a, .button)
                            }
                            .buttonStyle(.plain)
                            .disabled(inFlight || (needsEmail && !isValidEmail(approverEmail)))
                        }
                        .kidElement(a, .askForm)
                    }
                    if grownupFailed {
                        Text(
                            s.hasApproverEmail
                                ? t.error
                                : failedCode == .invalidRequest ? strings.askAnAdult.invalidEmail : strings.askAnAdult.error
                        )
                        .kidElement(a, .danger)
                    }
                }
            }
        }
        .onAppear { reseed(s.challenge) }
        .onChange(of: s.challenge) { reseed($0) }
    }
}

extension KIDPermissionSettings {
    @ViewBuilder
    private func emailField(_ placeholder: String) -> some View {
        #if os(iOS)
            TextField(placeholder, text: $approverEmail)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        #else
            TextField(placeholder, text: $approverEmail)
        #endif
    }
}

public struct KIDSettings: View {
    @EnvironmentObject private var core: KIDCoreContext

    public init() {}

    public var body: some View {
        let a = core.appearance
        VStack(alignment: .leading, spacing: 12) {
            Text(core.strings.settings.title).kidElement(a, .title)
            KIDPermissionSettings()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .kidElement(a, .card, .settings)
    }
}
