import SwiftUI

/// A button style that applies a Neumorphism effect to the button's
/// surface while coloring its label with the ambient tint, the mirror
/// image of ``NeumorphismProminentButtonStyle``.
///
/// This plays the same role that `bordered` plays next to
/// `borderedProminent`: pressing the button still flips its surface from
/// raised/convex to pressed/concave the same way
/// ``NeumorphismProminentButtonStyle`` does, but the surface itself keeps
/// its default (untinted) color — only the label picks up the ambient
/// `tint(_:)` view modifier (or the app's accent color).
///
/// ```swift
/// Button("Continue") { }
///     .buttonStyle(.neumorphism)
///     .tint(.blue)
/// ```
///
/// All of the actual rendering is done by
/// ``SwiftUI/View/neumorphismEffect(_:in:)`` — this style only supplies
/// the label's padding, colors the label, and swaps the style between
/// ``Neumorphism/regular`` and ``Neumorphism/pressed`` based on
/// `configuration.isPressed`.
///
/// Declared watchOS 7 here (matching `bordered`'s own floor) rather than
/// the watchOS 10 the `.neumorphism` extension below actually needs:
/// this struct itself is generic over any `Shape`, so it only inherits
/// whatever restriction the *specific* `Shape` a caller supplies brings
/// with it — `ButtonBorderShape`'s own `Shape` conformance is what's
/// watchOS-10-only, not this type.
@available(iOS 15.0, macOS 10.15, tvOS 13.0, watchOS 7.0, *)
public struct NeumorphismButtonStyle<S: Shape>: ButtonStyle {
    var style: Neumorphism
    var shape: S

    public func makeBody(configuration: Configuration) -> some View {
        NeumorphismButtonLabel(label: configuration.label, style: style, shape: shape, isPressed: configuration.isPressed)
    }
}

/// The actual rendered content of a ``NeumorphismButtonStyle`` button, as
/// its own named view: `configuration.isPressed` still drives which style
/// is shown, but this gives that varying value a single, stable view
/// identity to update in place (same type, same position in the tree) as
/// it changes, rather than only living as an inline ternary inside
/// `makeBody`'s returned expression.
private struct NeumorphismButtonLabel<Label: View, S: Shape>: View {
    var label: Label
    var style: Neumorphism
    var shape: S
    var isPressed: Bool

    var body: some View {
        let effectiveStyle = isPressed ? style.pressedVariant : style

        // Unlike `NeumorphismProminentButtonStyle`, the surface itself
        // never carries the tint, so there's no contrast problem to solve
        // here — the label can just use `.tint` directly, the same
        // unresolved `ShapeStyle` the surface would have followed if it
        // were the prominent style.
        label
            .foregroundStyle(.tint)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .neumorphismEffect(effectiveStyle, in: shape)
            // Without this, the system focus ring (Tab key navigation)
            // defaults to the label's bounding rectangle regardless of
            // `shape` — visibly square around a pill-shaped button.
            // `.focusEffect` itself is macOS-only (unavailable on
            // iOS/Mac Catalyst/tvOS/visionOS/watchOS), unlike the rest
            // of this view.
            .modifier(NeumorphismFocusEffectShape(shape: shape))
    }
}

/// Applies `.contentShape(.focusEffect, shape)` where that content
/// shape kind exists (macOS only) and does nothing everywhere else, so
/// ``NeumorphismButtonLabel``/``NeumorphismProminentButtonLabel`` don't
/// each need their own `#if os(macOS)` branch.
struct NeumorphismFocusEffectShape<S: Shape>: ViewModifier {
    var shape: S

    func body(content: Content) -> some View {
        #if os(macOS)
        content.contentShape(.focusEffect, shape)
        #else
        content
        #endif
    }
}

@available(iOS 15.0, macOS 10.15, tvOS 13.0, watchOS 10.0, *)
extension ButtonStyle where Self == NeumorphismButtonStyle<ButtonBorderShape> {
    /// A button style that applies a Neumorphism effect to the button's
    /// surface while coloring its label with the ambient tint.
    ///
    /// Raised vs. pressed is always driven by the button's own press state,
    /// never by a style argument — there's no `.neumorphism(_:)` that takes
    /// a ``Neumorphism`` value, unlike ``SwiftUI/View/neumorphismEffect(_:in:)``.
    /// Color comes from the ambient `tint(_:)` view modifier (or the app's
    /// accent color), the same way `bordered` works. The shape comes from
    /// the ambient `buttonBorderShape(_:)` view modifier (or an automatic,
    /// platform-appropriate default), the same way `bordered` and
    /// `borderedProminent` work.
    ///
    /// watchOS 10 here, not the `bordered`'s own watchOS 7 floor:
    /// `ButtonBorderShape`'s `Shape` conformance — needed since this
    /// fixes `S` to that concrete type — is itself only available from
    /// watchOS 10.
    public static var neumorphism: NeumorphismButtonStyle<ButtonBorderShape> {
        NeumorphismButtonStyle(style: .neutralButtonBase, shape: .buttonBorder)
    }
}

#Preview("Button") {
    VStack(spacing: 24) {
        Button("Regular") {}
            .buttonStyle(.neumorphism)

        Button("Tinted") {}
            .buttonStyle(.neumorphism)
            .tint(.blue)

        Button("Pink") {}
            .buttonStyle(.neumorphism)
            .tint(.pink)
    }
    .padding(60)
}
