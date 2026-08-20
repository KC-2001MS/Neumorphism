import SwiftUI

// `TextEditorStyle` doesn't exist in the watchOS SDK at all, and
// `PlainTextEditorStyle` (which `makeBody(configuration:)` below
// delegates to) doesn't exist on tvOS either — in both cases, not just
// restricted-but-present the way most of this package's other
// `@available(_, unavailable)` styles are. `@available` alone can't
// express that, since it still needs the referenced type itself to
// resolve when type-checking. This whole file is excluded from both
// platforms' builds instead.
#if !os(watchOS) && !os(tvOS)

/// A text editor style that renders as a Neumorphism-styled raised
/// (convex) card behind the editable text. The Neumorphism counterpart
/// to `AutomaticTextEditorStyle`, constructed via
/// ``SwiftUI/TextEditorStyle/neumorphism``.
///
/// ```swift
/// TextEditor(text: $note)
///     .textEditorStyle(.neumorphism)
/// ```
///
/// `TextEditorStyleConfiguration` exposes no discoverable property for
/// the editor's own editable content, and no `TextEditor.init(_
/// configuration:)` overload exists to delegate through either — unlike
/// `Toggle`, `ProgressView`, and `GroupBox`, which all support that
/// pattern. Delegating to `PlainTextEditorStyle`'s own
/// `makeBody(configuration:)` instead — a concrete, public style that
/// already knows how to render `configuration` correctly — sidesteps
/// that entirely: only a raised background is added on top, since a
/// text editor's own scrolling/selection/cursor behavior is left
/// entirely to the system.
@available(iOS 17.0, macOS 14.0, visionOS 1.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NeumorphismTextEditorStyle: TextEditorStyle {
    // The text area is a plain rectangle regardless of how the card
    // around it is clipped, so a padding smaller than the corner radius
    // leaves the text's own corners sitting right where the card curves
    // away underneath it — the inset needs to be at least the radius for
    // the text to stay clear of the curve on every side.
    private let cornerRadius: CGFloat = 12

    public func makeBody(configuration: Configuration) -> some View {
        PlainTextEditorStyle().makeBody(configuration: configuration)
            .padding(cornerRadius)
            .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

@available(iOS 17.0, macOS 14.0, visionOS 1.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension TextEditorStyle where Self == NeumorphismTextEditorStyle {
    /// A text editor style that renders as a Neumorphism-styled raised card.
    public static var neumorphism: NeumorphismTextEditorStyle {
        NeumorphismTextEditorStyle()
    }
}

/// The Neumorphism counterpart to `RoundedBorderTextEditorStyle`,
/// constructed via ``SwiftUI/TextEditorStyle/neumorphismRoundedBorder``.
///
/// `RoundedBorderTextEditorStyle` and `AutomaticTextEditorStyle` both
/// just describe a bordered box around the text — this package draws
/// both the same way, as a raised rounded-rectangle card, so this
/// simply reuses ``NeumorphismTextEditorStyle``'s rendering. Delegating
/// to it directly (rather than through a shared free function, the way
/// the watchOS-only Gauge styles do) is safe here since
/// `RoundedBorderTextEditorStyle` is real system counterpart is
/// visionOS-*only* — strictly narrower than `AutomaticTextEditorStyle`'s
/// iOS/macOS/visionOS support, so wherever this is available,
/// ``NeumorphismTextEditorStyle`` is guaranteed to be too.
@available(visionOS 1.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NeumorphismRoundedBorderTextEditorStyle: TextEditorStyle {
    public func makeBody(configuration: Configuration) -> some View {
        NeumorphismTextEditorStyle().makeBody(configuration: configuration)
    }
}

@available(visionOS 1.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension TextEditorStyle where Self == NeumorphismRoundedBorderTextEditorStyle {
    /// A text editor style that renders as a Neumorphism-styled raised card.
    public static var neumorphismRoundedBorder: NeumorphismRoundedBorderTextEditorStyle {
        NeumorphismRoundedBorderTextEditorStyle()
    }
}

#Preview("TextEditor") {
    @Previewable @State var text = "Some editable text goes here."

    TextEditor(text: $text)
        .textEditorStyle(.neumorphism)
        .frame(height: 120)
        .padding(60)
}

#endif
