import SwiftUI

/// A group box style that renders as a Neumorphism-styled card: a
/// raised (convex) panel holding the box's label and content.
///
/// ```swift
/// GroupBox("Wi-Fi") {
///     Toggle("Enabled", isOn: $isEnabled)
/// }
/// .groupBoxStyle(.neumorphism)
/// ```
///
/// Raised, never pressed: unlike a button or a toggle's track, a group
/// box has no pressed state and no structural need for a dent (nothing
/// slides or sits inset inside it) — a concave surface should only ever
/// show up where a control's own state or structure calls for one, and
/// a plain container calls for neither. Follows the default (untinted)
/// surface color, the same way ``NeumorphismButtonStyle`` does, rather
/// than the ambient `tint(_:)` view modifier — a card's own background
/// isn't the kind of thing an accent color should paint.
@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NeumorphismGroupBoxStyle: GroupBoxStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
            configuration.content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension GroupBoxStyle where Self == NeumorphismGroupBoxStyle {
    /// A group box style that renders as a Neumorphism-styled card.
    public static var neumorphism: NeumorphismGroupBoxStyle {
        NeumorphismGroupBoxStyle()
    }
}

// `GroupBox` the view (not just this style) is also unavailable on
// tvOS and watchOS, so this preview can't build for either platform's
// canvas.
#if !os(watchOS) && !os(tvOS)
#Preview("GroupBox") {
    VStack(spacing: 24) {
        GroupBox("Wi-Fi") {
            Text("Connected to Home Network")
        }
        .groupBoxStyle(.neumorphism)

        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text("No Title")
                Text("Just content.")
                    .font(.caption)
            }
        }
        .groupBoxStyle(.neumorphism)
    }
    .padding(60)
}
#endif
