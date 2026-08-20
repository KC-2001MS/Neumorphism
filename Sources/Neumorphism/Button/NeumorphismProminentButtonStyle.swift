import SwiftUI

/// A button style that applies a Neumorphism effect based on the button's context.
///
/// This plays the same role that `PrimitiveButtonStyle.glass` plays for
/// Liquid Glass: pressing the button flips its surface from raised/convex
/// to pressed/concave, the same way physically pressing a soft-UI button
/// dents it inward rather than flattening it — driven entirely by the
/// button's own press state, never by a style argument.
///
/// ```swift
/// Button("Continue") { }
///     .buttonStyle(.neumorphismProminent)
///     .tint(.blue)
/// ```
///
/// Color comes from the ambient `tint(_:)` view modifier (falling back to
/// the app's accent color), the same way `borderedProminent` works. All of
/// the actual rendering is done by ``SwiftUI/View/neumorphismEffect(_:in:)``
/// — this style only supplies the label's padding and swaps the style
/// between ``Neumorphism/regular`` and ``Neumorphism/pressed`` based on
/// `configuration.isPressed`.
/// Declared watchOS 8 here (matching `borderedProminent`'s own floor)
/// rather than the watchOS 10 the `.neumorphismProminent` extension
/// below actually needs — see the identical note on
/// ``NeumorphismButtonStyle``.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct NeumorphismProminentButtonStyle<S: Shape>: ButtonStyle {
    var style: Neumorphism
    var shape: S

    public func makeBody(configuration: Configuration) -> some View {
        NeumorphismProminentButtonLabel(label: configuration.label, style: style, shape: shape, isPressed: configuration.isPressed)
    }
}

/// The actual rendered content of a ``NeumorphismProminentButtonStyle`` button, as
/// its own named view: `configuration.isPressed` still drives which style
/// is shown, but this gives that varying value a single, stable view
/// identity to update in place (same type, same position in the tree) as
/// it changes, rather than only living as an inline ternary inside
/// `makeBody`'s returned expression.
private struct NeumorphismProminentButtonLabel<Label: View, S: Shape>: View {
    var label: Label
    var style: Neumorphism
    var shape: S
    var isPressed: Bool

    @Environment(\.self) private var environment

    var body: some View {
        let effectiveStyle = isPressed ? style.pressedVariant : style

        // An ambient tint never resolves to a concrete `Color` in Swift
        // code, so there's no way to compute "is this background light or
        // dark" ourselves and pick black or white directly. A same-colored
        // shim behind a solid white swatch, diffed with `.blendMode(.difference)`,
        // gets the GPU to compute the real distance from white at draw
        // time — but left alone that distance is a hue (e.g. orange on
        // blue), not a black/white choice, and doing this on the label
        // itself would also recolor the transparent gaps *between*
        // glyphs (wherever that background is itself far from white),
        // washing the whole label into one flat block. Computing it on a
        // separate opaque swatch instead avoids that: `.compositingGroup()`
        // bakes the diff into real pixels, `.saturation(0)` collapses the
        // resulting hue to a brightness, `.brightness`/`.contrast` push it
        // to a hard split (biased so only a background genuinely close to
        // white lands on black, anything else lands on white), and
        // `.mask(label)` is what finally cuts that uniform color down to
        // just the glyph shapes, leaving the gaps transparent.
        label
            .hidden()
            .overlay {
                Color.white
                    .blendMode(.difference)
                    .background(effectiveStyle.resolvedFill(in: environment))
                    .compositingGroup()
                    .saturation(0)
                    .brightness(0.35)
                    .contrast(20)
                    .mask(label)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .neumorphismEffect(effectiveStyle, in: shape)
            // Without this, the system focus ring (Tab key navigation)
            // defaults to the label's bounding rectangle regardless of
            // `shape` — visibly square around a pill-shaped button.
            // `.focusEffect` itself is macOS-only — see
            // `NeumorphismFocusEffectShape` next to
            // ``NeumorphismButtonStyle``.
            .modifier(NeumorphismFocusEffectShape(shape: shape))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 10.0, *)
extension ButtonStyle where Self == NeumorphismProminentButtonStyle<ButtonBorderShape> {
    /// A button style that applies a Neumorphism effect based on the button's context.
    ///
    /// Raised vs. pressed is always driven by the button's own press state,
    /// never by a style argument — there's no `.neumorphismProminent(_:)` that takes
    /// a ``Neumorphism`` value, unlike ``SwiftUI/View/neumorphismEffect(_:in:)``.
    /// Color comes from the ambient `tint(_:)` view modifier (or the app's
    /// accent color), the same way `borderedProminent` works. The shape
    /// comes from the ambient `buttonBorderShape(_:)` view modifier (or an
    /// automatic, platform-appropriate default), the same way `bordered`
    /// and `borderedProminent` work.
    ///
    /// watchOS 10 here, not `borderedProminent`'s own watchOS 8 floor —
    /// see the identical note on ``NeumorphismButtonStyle/neumorphism``.
    public static var neumorphismProminent: NeumorphismProminentButtonStyle<ButtonBorderShape> {
        NeumorphismProminentButtonStyle(style: .buttonBase, shape: .buttonBorder)
    }
}


#Preview("Button") {
    VStack(spacing: 24) {
        Button("Regular") {}
            .buttonStyle(.neumorphismProminent)

        Button("Tinted") {}
            .buttonStyle(.neumorphismProminent)
            .tint(.blue)

        Button("Pink") {}
            .buttonStyle(.neumorphismProminent)
            .tint(.pink)
    }
    .padding(60)
}
