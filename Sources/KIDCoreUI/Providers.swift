import Combine
import SwiftUI

enum DeclarationStatus: String, Sendable {
    case ready, pending, error
}

@MainActor
public final class KIDCoreContext: ObservableObject {
    let client: any KIDClient
    let sessions = SessionStore()
    let asks: AskWatcher
    @Published var appearance: Appearance
    @Published public private(set) var strings: KIDStrings
    @Published private(set) var locale: String?
    @Published public private(set) var jurisdictions: [JurisdictionOption]
    @Published private(set) var declarationStatus: DeclarationStatus
    /// Why declare failed, with `declarationStatus == .error`.
    private(set) var declarationError: Error?

    private let declareInput: KIDDeclare?
    private let sleep: @Sendable (Int) async -> Void
    private var started = false
    let tasks = TaskTracker()

    init(
        client: any KIDClient,
        publishableKey: String,
        appearance: Appearance,
        localization: KIDLocalization?,
        declare: KIDDeclare?,
        sleep: @escaping @Sendable (Int) async -> Void = { try? await Task.sleep(nanoseconds: UInt64($0) * 1_000_000) }
    ) {
        self.client = client
        asks = AskWatcher(client: client, sessions: sessions)
        asks.start()
        self.appearance = appearance
        strings = mergeStrings(localization)
        locale = localization?.locale
        jurisdictions = localizeJurisdictions(mergeStrings(localization), localization?.locale)
        declareInput = isLiveKey(publishableKey) ? nil : declare
        self.sleep = sleep
        declarationStatus = declareInput == nil ? .ready : .pending
    }

    func setLocalization(_ localization: KIDLocalization?) {
        strings = mergeStrings(localization)
        locale = localization?.locale
        jurisdictions = localizeJurisdictions(strings, locale)
    }

    // Content that renders nothing never fires onAppear, so the provider starts its work when it is created.
    func startingSoon() -> Self {
        DispatchQueue.main.async { [weak self] in self?.start() }
        return self
    }

    func start() {
        guard let declareInput, !started else { return }
        started = true

        tasks.spawn { [weak self] in
            var attempt = 1
            while let self {
                do {
                    try await self.client.declare(declareInput)
                    self.declarationStatus = .ready
                    return
                } catch {
                    if attempt >= MAX_DECLARE_ATTEMPTS || !isRetryableDeclareError(error) {
                        defaultLog(.error, "declare failed \(error)")
                        self.declarationError = error
                        self.declarationStatus = .error
                        return
                    }
                    await self.sleep(declareRetryDelayMs(attempt))
                    attempt += 1
                }
            }
        }
    }
}

public struct KIDCoreProvider<Content: View>: View {
    @StateObject private var core: KIDCoreContext
    private let appearance: Appearance
    private let localization: KIDLocalization?
    private let content: Content

    public init(
        publishableKey: String,
        baseURL: URL,
        appearance: Appearance = Appearance(),
        localization: KIDLocalization? = nil,
        declare: KIDDeclare? = nil,
        @ViewBuilder content: () -> Content
    ) {
        _core = StateObject(
            wrappedValue: KIDCoreContext(
                client: createClient(ClientOptions(publishableKey: publishableKey, baseURL: baseURL)),
                publishableKey: publishableKey,
                appearance: appearance,
                localization: localization,
                declare: declare
            ).startingSoon())
        self.appearance = appearance
        self.localization = localization
        self.content = content()
    }

    init(core: KIDCoreContext, @ViewBuilder content: () -> Content) {
        _core = StateObject(wrappedValue: core.startingSoon())
        appearance = core.appearance
        localization = nil
        self.content = content()
    }

    public var body: some View {
        content
            .environmentObject(core)
            .onChange(of: appearance) { core.appearance = $0 }
            .onChange(of: localization) { core.setLocalization($0) }
            .environment(\.kidLayoutDirection, textDirection(localization?.locale))
    }
}

public struct KIDSessionProvider<Content: View>: View {
    @EnvironmentObject private var core: KIDCoreContext
    private let inputs: AgeGateInputs
    private let onChallenge: ((String) -> Void)?
    private let onSession: ((String) -> Void)?
    private let onClaim: ((String) -> Void)?
    private let content: Content

    /// - Parameters:
    ///   - jurisdiction: An ISO 3166-1 country or ISO 3166-2 subdivision code, or `.auto` to resolve it from the
    ///     client IP (falling back to the picker). Omit to show the picker.
    ///   - onClaim: Called once the age check has a result, passed or pending, with a one-time token for your backend.
    ///     Not called on resume or when the player is prohibited.
    public init(
        jurisdiction: JurisdictionCode? = nil,
        age: AgeSignal? = nil,
        email: String? = nil,
        challengeId: String? = nil,
        sessionId: String? = nil,
        onChallenge: ((String) -> Void)? = nil,
        onSession: ((String) -> Void)? = nil,
        onClaim: ((String) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        inputs = AgeGateInputs(
            jurisdiction: jurisdiction?.rawValue,
            age: age,
            email: email,
            challengeId: challengeId,
            sessionId: sessionId
        )
        self.onChallenge = onChallenge
        self.onSession = onSession
        self.onClaim = onClaim
        self.content = content()
    }

    public var body: some View {
        KIDSessionRunner(
            core: core,
            inputs: inputs,
            onChallenge: onChallenge,
            onSession: onSession,
            onClaim: onClaim,
            content: content
        )
    }
}

private struct DeclarativeInputs: Equatable {
    var jurisdiction: String?
    var age: AgeSignal?
    var email: String?
}

@MainActor
private final class AgeGateLifecycle: ObservableObject {
    let controller: AgeGateController
    private var declaration: AnyCancellable?

    init(core: KIDCoreContext, inputs: AgeGateInputs) {
        let controller = AgeGateController(
            client: core.client, initial: inputs, platformAgeSignal: defaultPlatformAgeSignalProvider(),
            sessions: core.sessions)
        self.controller = controller
        declaration = core.$declarationStatus.removeDuplicates().receive(on: DispatchQueue.main)
            .sink { [weak controller, weak core] status in
                switch status {
                case .ready: controller?.start()
                case .error: controller?.declarationFailed(core?.declarationError)
                case .pending: break
                }
            }
    }
}

private struct KIDSessionRunner<Content: View>: View {
    @StateObject private var lifecycle: AgeGateLifecycle
    @ObservedObject private var core: KIDCoreContext
    @State private var firedChallenge: String?
    @State private var firedSession: String?
    @State private var firedClaim: String?
    let inputs: AgeGateInputs
    let onChallenge: ((String) -> Void)?
    let onSession: ((String) -> Void)?
    let onClaim: ((String) -> Void)?
    let content: Content

    init(
        core: KIDCoreContext,
        inputs: AgeGateInputs,
        onChallenge: ((String) -> Void)?,
        onSession: ((String) -> Void)?,
        onClaim: ((String) -> Void)?,
        content: Content
    ) {
        _lifecycle = StateObject(wrappedValue: AgeGateLifecycle(core: core, inputs: inputs))
        self.core = core
        self.inputs = inputs
        self.onChallenge = onChallenge
        self.onSession = onSession
        self.onClaim = onClaim
        self.content = content
    }

    private var controller: AgeGateController { lifecycle.controller }

    private var declarative: DeclarativeInputs {
        DeclarativeInputs(jurisdiction: inputs.jurisdiction, age: inputs.age, email: inputs.email)
    }

    private func configure(_ d: DeclarativeInputs) {
        controller.configure(jurisdiction: d.jurisdiction, age: d.age, email: d.email)
    }

    var body: some View {
        content
            .environmentObject(controller)
            .onAppear {
                configure(declarative)
                if core.declarationStatus == .ready { controller.start() }
            }
            .onDisappear { controller.destroy() }
            .onChange(of: declarative) { configure($0) }
            .onReceive(controller.$state.map(resumableChallengeId).removeDuplicates()) { id in
                guard let id, id != firedChallenge else { return }
                firedChallenge = id
                onChallenge?(id)
            }
            .onReceive(controller.$state.map(\.sessionId).removeDuplicates()) { id in
                guard let id, id != firedSession else { return }
                firedSession = id
                onSession?(id)
            }
            .onReceive(controller.$state.map(\.claimToken).removeDuplicates()) { token in
                guard let token, token != firedClaim else { return }
                firedClaim = token
                onClaim?(token)
            }
    }
}

public struct KIDSettingsProvider<Content: View>: View {
    @EnvironmentObject private var core: KIDCoreContext
    private let inputs: SettingsInputs
    private let onChallenge: ((String) -> Void)?
    private let content: Content

    /// - Parameters:
    ///   - onChallenge: Called with the settings challenge id once its email is sent; persist it to resume.
    public init(
        sessionId: String,
        challengeId: String? = nil,
        onChallenge: ((String) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        inputs = SettingsInputs(sessionId: sessionId, challengeId: challengeId)
        self.onChallenge = onChallenge
        self.content = content()
    }

    public var body: some View {
        KIDSettingsRunner(
            client: core.client, sessions: core.sessions, asks: core.asks, inputs: inputs, onChallenge: onChallenge,
            content: content)
    }
}

@MainActor
private final class CallbackBox {
    var callback: ((String) -> Void)?
}

private struct KIDSettingsRunner<Content: View>: View {
    @StateObject private var controller: SettingsController
    @State private var box: CallbackBox
    let onChallenge: ((String) -> Void)?
    let content: Content

    init(
        client: any KIDClient, sessions: SessionStore, asks: AskWatcher, inputs: SettingsInputs,
        onChallenge: ((String) -> Void)?, content: Content
    ) {
        let box = CallbackBox()
        _box = State(wrappedValue: box)
        _controller = StateObject(
            wrappedValue: SettingsController(
                client: client, initial: inputs, onChallenge: { box.callback?($0) }, sessions: sessions, asks: asks
            ).startingSoon()
        )
        self.onChallenge = onChallenge
        self.content = content
    }

    var body: some View {
        box.callback = onChallenge
        return content
            .environmentObject(controller)
            .onAppear { controller.start() }
            .onDisappear { controller.destroy() }
    }
}
