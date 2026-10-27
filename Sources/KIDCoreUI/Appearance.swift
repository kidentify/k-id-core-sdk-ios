import SwiftUI

public struct AppearanceVariables: Equatable, Sendable {
    public var colorPrimary: Color
    public var colorOnPrimary: Color
    public var colorText: Color
    public var colorTextMuted: Color
    public var colorSurface: Color
    public var colorSurfaceMuted: Color
    public var colorBorder: Color
    public var colorDanger: Color
    public var fontFamily: String?
    public var radius: CGFloat

    public init(
        colorPrimary: Color = Color(kidHex: 0x4F46E5),
        colorOnPrimary: Color = Color(kidHex: 0xFFFFFF),
        colorText: Color = Color(kidHex: 0x111827),
        colorTextMuted: Color = Color(kidHex: 0x6B7280),
        colorSurface: Color = Color(kidHex: 0xFFFFFF),
        colorSurfaceMuted: Color = Color(kidHex: 0xF3F4F6),
        colorBorder: Color = Color(kidHex: 0xE5E7EB),
        colorDanger: Color = Color(kidHex: 0xDC2626),
        fontFamily: String? = nil,
        radius: CGFloat = 12
    ) {
        self.colorPrimary = colorPrimary
        self.colorOnPrimary = colorOnPrimary
        self.colorText = colorText
        self.colorTextMuted = colorTextMuted
        self.colorSurface = colorSurface
        self.colorSurfaceMuted = colorSurfaceMuted
        self.colorBorder = colorBorder
        self.colorDanger = colorDanger
        self.fontFamily = fontFamily
        self.radius = radius
    }
}

public struct KIDElementStyle: Equatable, Sendable {
    public var foregroundColor: Color?
    public var backgroundColor: Color?
    public var borderColor: Color?
    public var font: Font?
    public var padding: EdgeInsets?
    public var cornerRadius: CGFloat?

    public init(
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        borderColor: Color? = nil,
        font: Font? = nil,
        padding: EdgeInsets? = nil,
        cornerRadius: CGFloat? = nil
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.font = font
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    func merged(over base: KIDElementStyle) -> KIDElementStyle {
        KIDElementStyle(
            foregroundColor: foregroundColor ?? base.foregroundColor,
            backgroundColor: backgroundColor ?? base.backgroundColor,
            borderColor: borderColor ?? base.borderColor,
            font: font ?? base.font,
            padding: padding ?? base.padding,
            cornerRadius: cornerRadius ?? base.cornerRadius
        )
    }
}

public enum ElementName: String, CaseIterable, Sendable {
    case card, title, label, input, button, muted, danger, row, pill, pillAsk, pillAdded, askForm, controlColumn
    case verifyAge, selectJurisdiction, collectAge, askAnAdult, settings
}

public struct Appearance: Equatable, Sendable {
    public var variables: AppearanceVariables
    public var elements: [ElementName: KIDElementStyle]

    public init(variables: AppearanceVariables = AppearanceVariables(), elements: [ElementName: KIDElementStyle] = [:]) {
        self.variables = variables
        self.elements = elements
    }
}

extension Color {
    @usableFromInline init(kidHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension AppearanceVariables {
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let fontFamily else { return .system(size: size, weight: weight) }
        return .custom(fontFamily, size: size).weight(weight)
    }
}

func defaultElementStyle(_ key: ElementName, _ v: AppearanceVariables) -> KIDElementStyle {
    switch key {
    case .card:
        return KIDElementStyle(
            foregroundColor: v.colorText,
            backgroundColor: v.colorSurface,
            borderColor: v.colorBorder,
            font: v.font(size: 16),
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            cornerRadius: v.radius
        )
    case .title: return KIDElementStyle(font: v.font(size: 16, weight: .semibold))
    case .label: return KIDElementStyle(font: v.font(size: 14, weight: .semibold))
    case .input:
        return KIDElementStyle(
            borderColor: v.colorBorder,
            padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12),
            cornerRadius: v.radius / 2
        )
    case .button:
        return KIDElementStyle(
            foregroundColor: v.colorOnPrimary,
            backgroundColor: v.colorPrimary,
            font: v.font(size: 16, weight: .semibold),
            padding: EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14),
            cornerRadius: v.radius / 2
        )
    case .muted: return KIDElementStyle(foregroundColor: v.colorTextMuted, font: v.font(size: 14))
    case .danger: return KIDElementStyle(foregroundColor: v.colorDanger, font: v.font(size: 14))
    case .pill:
        return KIDElementStyle(
            font: v.font(size: 13, weight: .semibold),
            padding: EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12),
            cornerRadius: 999
        )
    case .pillAsk: return KIDElementStyle(foregroundColor: v.colorText, borderColor: v.colorBorder)
    case .pillAdded:
        return KIDElementStyle(foregroundColor: v.colorOnPrimary, backgroundColor: v.colorPrimary, borderColor: v.colorPrimary)
    default: return KIDElementStyle()
    }
}

func resolveElementStyle(_ appearance: Appearance, _ keys: [ElementName]) -> KIDElementStyle {
    let defaults = keys.reduce(KIDElementStyle()) { defaultElementStyle($1, appearance.variables).merged(over: $0) }
    return keys.reduce(defaults) { appearance.elements[$1]?.merged(over: $0) ?? $0 }
}

private struct KIDLayoutDirectionKey: EnvironmentKey {
    static let defaultValue: LayoutDirection? = nil
}

extension EnvironmentValues {
    var kidLayoutDirection: LayoutDirection? {
        get { self[KIDLayoutDirectionKey.self] }
        set { self[KIDLayoutDirectionKey.self] = newValue }
    }
}

struct KIDElementModifier: ViewModifier {
    @Environment(\.kidLayoutDirection) private var direction
    @Environment(\.layoutDirection) private var hostDirection
    let style: KIDElementStyle

    func body(content: Content) -> some View {
        let radius = style.cornerRadius ?? 0
        content
            .environment(\.layoutDirection, direction ?? hostDirection)
            .modifier(OptionalFont(font: style.font))
            .modifier(OptionalForeground(color: style.foregroundColor))
            .padding(style.padding ?? EdgeInsets())
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(style.backgroundColor ?? .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(style.borderColor ?? .clear, lineWidth: style.borderColor == nil ? 0 : 1)
            )
    }
}

private struct OptionalFont: ViewModifier {
    let font: Font?

    func body(content: Content) -> some View {
        if let font { content.font(font) } else { content }
    }
}

private struct OptionalForeground: ViewModifier {
    let color: Color?

    func body(content: Content) -> some View {
        if let color { content.foregroundColor(color) } else { content }
    }
}

extension View {
    func kidElement(_ appearance: Appearance, _ keys: ElementName...) -> some View {
        modifier(KIDElementModifier(style: resolveElementStyle(appearance, keys)))
    }
}
