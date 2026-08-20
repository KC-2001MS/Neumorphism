import SwiftUI

/// A disclosure group style that renders as a Neumorphism-styled card: a
/// raised (convex) panel holding a tappable header (with a rotating
/// chevron) and, once expanded, the group's content.
///
/// ```swift
/// DisclosureGroup("Settings", isExpanded: $isExpanded) {
///     Text("More options here")
/// }
/// .disclosureGroupStyle(.neumorphism)
/// ```
///
/// Raised, never pressed: a disclosure group has no pressed state and no
/// structural need for a dent — the same reasoning
/// ``NeumorphismGroupBoxStyle`` follows. Follows the default (untinted)
/// surface color rather than the ambient `tint(_:)` view modifier, the
/// same way ``NeumorphismButtonStyle`` does.
@available(iOS 16.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NeumorphismDisclosureGroupStyle: DisclosureGroupStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.15)) {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if configuration.isExpanded {
                configuration.content
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 16.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DisclosureGroupStyle where Self == NeumorphismDisclosureGroupStyle {
    /// A disclosure group style that renders as a Neumorphism-styled card.
    public static var neumorphism: NeumorphismDisclosureGroupStyle {
        NeumorphismDisclosureGroupStyle()
    }
}

// `DisclosureGroup` the view (not just this style) is also unavailable
// on tvOS and watchOS, so this preview can't build for either
// platform's canvas.
#if !os(watchOS) && !os(tvOS)
#Preview("DisclosureGroup") {
    @Previewable @State var isExpanded = true

    VStack(spacing: 24) {
        DisclosureGroup("Wi-Fi Settings", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Network: Home")
                Text("Password protected")
                    .font(.caption)
            }
        }
        .disclosureGroupStyle(.neumorphism)

        DisclosureGroup("Collapsed") {
            Text("Hidden content")
        }
        .disclosureGroupStyle(.neumorphism)
    }
    .padding(60)
}
#endif
