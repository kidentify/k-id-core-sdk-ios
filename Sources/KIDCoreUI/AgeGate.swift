import SwiftUI

public protocol KIDAgeGateSlot {
    var slotStatus: KIDStatus { get }
    var slotView: AnyView { get }
}

public struct KIDAgeGatePending<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .pending }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDAgeGateProhibited<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .prohibited }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDAgeGateFail<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .fail }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDAgeGatePass<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .pass }
    public var slotView: AnyView { AnyView(content) }
}

public struct KIDAgeGateError<Content: View>: KIDAgeGateSlot {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var slotStatus: KIDStatus { .error }
    public var slotView: AnyView { AnyView(content) }
}

@resultBuilder
public enum KIDAgeGateSlotBuilder {
    public static func buildExpression(_ slot: some KIDAgeGateSlot) -> [any KIDAgeGateSlot] { [slot] }
    public static func buildBlock(_ parts: [any KIDAgeGateSlot]...) -> [any KIDAgeGateSlot] { parts.flatMap { $0 } }
    public static func buildOptional(_ part: [any KIDAgeGateSlot]?) -> [any KIDAgeGateSlot] { part ?? [] }
    public static func buildEither(first: [any KIDAgeGateSlot]) -> [any KIDAgeGateSlot] { first }
    public static func buildEither(second: [any KIDAgeGateSlot]) -> [any KIDAgeGateSlot] { second }
}

public struct KIDAgeGate: View {
    @EnvironmentObject private var flow: AgeGateController
    private let slots: [any KIDAgeGateSlot]

    public init(@KIDAgeGateSlotBuilder slots: () -> [any KIDAgeGateSlot] = { [] }) {
        self.slots = slots()
    }

    public var body: some View {
        if flow.state.status == .running {
            KIDSelectJurisdiction()
            KIDCollectAge()
            KIDAskAnAdult()
            KIDVerifyAge()
        } else if let slot = slots.last(where: { $0.slotStatus == flow.state.status }) {
            slot.slotView
        }
    }
}
