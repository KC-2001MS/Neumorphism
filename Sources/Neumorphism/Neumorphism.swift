// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

/// A style that describes how to render Neumorphism (soft UI) shading.
///
/// `Neumorphism` plays the same role for this material that
/// [`Glass`](https://developer.apple.com/documentation/swiftui/glass) plays
/// for the Liquid Glass material introduced in iOS 26: a small, composable
/// value that you configure and pass to
/// ``SwiftUI/View/neumorphismEffect(_:in:)`` or to
/// ``SwiftUI/ButtonStyle/neumorphism``, the same way you'd pass `.regular`
/// or `.clear` to `glassEffect(_:in:)`.
public struct Neumorphism: Sendable, Hashable {
    enum Variant: Sendable, Hashable {
        case flat
        case raised
        case pressed
    }

    var variant: Variant
    var tintColor: Color
    var isTintCustomized: Bool
    var customLightSource: Color?
    var customDarkSource: Color?
    var intensity: Double
    var glowStops: Double

    /// Whether an uncustomized `tintColor` should follow the ambient
    /// `tint(_:)` view modifier instead of ``defaultTint``. Only set by
    /// ``buttonBase``, which ``SwiftUI/ButtonStyle/neumorphism`` builds on:
    /// unlike an explicit ``tint(_:)``, an ambient tint never resolves to a
    /// concrete `Color` in Swift code (the renderer substitutes it at draw
    /// time), so the adaptive highlight/shadow boosts have no brightness to
    /// read and are skipped in favor of a fixed-opacity darken. See
    /// ``resolvedFill()``.
    private(set) var followsAmbientTint: Bool

    /// How far the outer glow's shadow-casting shape duplicate is shrunk,
    /// offset, and blurred. Smaller components (buttons) need
    /// proportionally larger values to stay visible; larger ones (cards)
    /// need smaller values to avoid ballooning past the shape. Only
    /// customized by ``buttonBase``.
    private(set) var outerGlowPadding: Double
    private(set) var outerGlowOffset: Double
    private(set) var outerGlowBlur: Double

    /// The direction and magnitude of the inner near/far shadow pair,
    /// in the same coded coordinate space `ShadowStyle.inner` uses
    /// (positive renders toward the top-left, negative toward the
    /// bottom-right — see the note on ``NeumorphismEffect``). Defaults
    /// to a diagonal offset, matching every flat or rounded-rect
    /// surface in this package. Only overridden by
    /// ``gaugeRingTrackBase``: a fixed *diagonal* offset breaks the
    /// left-right mirror symmetry of a circular ring shape (it reverses
    /// which of the ring's inner/outer edges reads as the near wall
    /// partway around the circle), which a purely vertical offset,
    /// aligned with that shape's own axis of symmetry, does not.
    private(set) var shadowOffset: CGSize

    private init(
        variant: Variant,
        tintColor: Color = Neumorphism.defaultTint,
        isTintCustomized: Bool = false,
        customLightSource: Color? = nil,
        customDarkSource: Color? = nil,
        intensity: Double = 1,
        glowStops: Double = 1,
        followsAmbientTint: Bool = false,
        outerGlowPadding: Double = 10,
        outerGlowOffset: Double = 10,
        outerGlowBlur: Double = 5,
        shadowOffset: CGSize = CGSize(width: 3, height: 3)
    ) {
        self.variant = variant
        self.tintColor = tintColor
        self.isTintCustomized = isTintCustomized
        self.customLightSource = customLightSource
        self.customDarkSource = customDarkSource
        self.intensity = intensity
        self.glowStops = glowStops
        self.followsAmbientTint = followsAmbientTint
        self.outerGlowPadding = outerGlowPadding
        self.outerGlowOffset = outerGlowOffset
        self.outerGlowBlur = outerGlowBlur
        self.shadowOffset = shadowOffset
    }

    /// How much to scale the inner highlight/shadow strength, based on `tintColor`. See ``contrastBoosts(of:in:)``.
    func innerContrastBoosts(in environment: EnvironmentValues, isFillColorKnown: Bool) -> (highlight: Double, shadow: Double) {
        guard isFillColorKnown else { return (1, 1) }
        return Neumorphism.contrastBoosts(of: tintColor, in: environment)
    }

    /// The outer highlight color cast onto the page background, brightened.
    /// Always derived from `environment.neumorphismBackground` (registered
    /// by ``SwiftUI/View/neumorphismBackground(_:)``), not the shape's own
    /// tint, so a blue button still casts a neutral halo matching the page
    /// behind it — and matching the *actual* page color, not a fixed gray,
    /// once that page has registered its real background color.
    static func outerLightSource(in environment: EnvironmentValues, delta: Double = 0.25) -> Color {
        adjustingBrightness(of: environment.neumorphismBackground, by: delta, in: environment)
    }

    /// The outer shadow color cast onto the page background. See ``outerLightSource(in:)``.
    static func outerDarkSource(in environment: EnvironmentValues, delta: Double = 0.25) -> Color {
        adjustingBrightness(of: environment.neumorphismBackground, by: -delta, in: environment)
    }

    /// How much to scale the highlight/shadow strength drawn on top of
    /// `color`: strong highlight / weak shadow only for colors that read as
    /// genuinely white (a strict `smoothstep`, not a linear ramp — a
    /// medium-gray surface should read with a present shadow, not a faint
    /// one). Saturated colors are pulled partway back toward no adjustment,
    /// since a colored tint isn't "failing to be white," it's just colored
    /// — but only partway: a fully saturated color can still be just as
    /// dark as a neutral gray (saturation and brightness are independent),
    /// and `mixedTowardBlack` only ever deepens a color along its own hue,
    /// so there's no risk of a saturated shadow looking muddy the way a
    /// naive translucent darken once did.
    static func contrastBoosts(of color: Color, in environment: EnvironmentValues) -> (highlight: Double, shadow: Double) {
        let resolved = color.resolve(in: environment)
        let red = Double(resolved.red)
        let green = Double(resolved.green)
        let blue = Double(resolved.blue)

        let brightness = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let maxComponent = max(red, max(green, blue))
        let minComponent = min(red, min(green, blue))
        let saturation = maxComponent > 0 ? (maxComponent - minComponent) / maxComponent : 0

        let whiteness = smoothstep(0.55, 0.85, brightness)
        let rawHighlight = 0.4 + 0.6 * whiteness
        // Even a fully white surface keeps a real shadow floor (2.0, not
        // 1.0/no-boost): a white-on-white raised shape is nearly
        // indistinguishable from its background to begin with, so it needs
        // the shadow to carry the contrast, not just the highlight.
        let rawShadow = 2.0 + 0.8 * (1 - whiteness)

        // Lerp each value toward 1 (no adjustment) as saturation increases,
        // capped so even a fully saturated color keeps most of its
        // brightness-based boost.
        let saturationPull = 0.4 * saturation
        let highlight = rawHighlight + (1 - rawHighlight) * saturationPull
        let shadow = rawShadow + (1 - rawShadow) * saturationPull
        return (highlight, shadow)
    }

    /// A smooth 0...1 ramp that's exactly `0` at or below `edge0` and exactly `1` at or above `edge1`.
    private static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = min(1, max(0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    /// Returns `color` (resolved against `environment`) with its brightness shifted by `delta` (clamped to `0...1`), keeping its hue and saturation.
    private static func adjustingBrightness(of color: Color, by delta: Double, in environment: EnvironmentValues) -> Color {
        let resolved = color.resolve(in: environment)

        return Color(
            red: min(1, max(0, Double(resolved.red) + delta)),
            green: min(1, max(0, Double(resolved.green) + delta)),
            blue: min(1, max(0, Double(resolved.blue) + delta)),
            opacity: Double(resolved.opacity)
        )
    }

    /// Returns `color` blended toward black by `fraction` (`0` = unchanged, `1` = solid black), fully opaque.
    ///
    /// Used instead of a translucent dark color for the inner shadow: a
    /// semi-transparent color composited by `ShadowStyle.inner` washes out
    /// noticeably lighter than the same color painted fully opaque (SwiftUI
    /// composites shadow alpha in a way that doesn't match naive alpha
    /// blending). Painting an already-mostly-original, mostly-opaque color
    /// avoids relying on that blend, so the result reliably reads as darker
    /// than the surface rather than washed out.
    static func mixedTowardBlack(_ color: Color, by fraction: Double, in environment: EnvironmentValues) -> Color {
        let resolved = color.resolve(in: environment)
        let scale = 1 - min(1, max(0, fraction))
        return Color(
            red: Double(resolved.red) * scale,
            green: Double(resolved.green) * scale,
            blue: Double(resolved.blue) * scale,
            opacity: 1
        )
    }

    /// Returns `color` blended toward white by `fraction` (`0` = unchanged, `1` = solid white), fully opaque. The mirror image of ``mixedTowardBlack(_:by:in:)``.
    ///
    /// Used as a redundant, subtle brightening on the raised state's far
    /// (bottom-right) wall: the outer shadow darkens the background beside
    /// the shape, but if that background is already near-black, darkening
    /// it further clamps to the same black and the shadow disappears — the
    /// mirror image of a near-white surface swallowing the outer highlight.
    /// This has no effect at all on a near-white surface (no headroom to
    /// brighten further, same reason `mixedTowardBlack` has none going the
    /// other way at black), so it only ever matters for the dark case.
    static func mixedTowardWhite(_ color: Color, by fraction: Double, in environment: EnvironmentValues) -> Color {
        let resolved = color.resolve(in: environment)
        let amount = min(1, max(0, fraction))
        return Color(
            red: Double(resolved.red) + (1 - Double(resolved.red)) * amount,
            green: Double(resolved.green) + (1 - Double(resolved.green)) * amount,
            blue: Double(resolved.blue) + (1 - Double(resolved.blue)) * amount,
            opacity: 1
        )
    }


    /// The default surface color when no explicit ``tint(_:)`` is set.
    ///
    /// Deliberately the platform's own standard content background
    /// (`UIColor.systemBackground` / `NSColor.windowBackgroundColor`)
    /// rather than a custom-picked gray: it still adapts between Light and
    /// Dark Mode, but the exact values come from the system, not from this
    /// package's own judgment call.
    static let defaultTint: Color = {
        #if os(watchOS) || os(tvOS)
        // `UIColor.systemBackground` doesn't exist on watchOS or tvOS
        // (both build on a plain black background, not an adaptive
        // light/dark one), so this falls back to the same fixed black
        // every app on either platform already renders against.
        .black
        #elseif canImport(UIKit)
        Color(uiColor: .systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(white: 0.9)
        #endif
    }()

    /// A surface that looks raised (convex), protruding out from the background using a paired drop shadow.
    ///
    /// This is the default variant, the same way `Glass.regular` is the
    /// default for `glassEffect(_:in:)`.
    public static let regular = Neumorphism(variant: .raised)

    /// A surface that looks pressed into the background (concave) using a paired inner shadow, the inset counterpart to ``regular``.
    public static let pressed = Neumorphism(variant: .pressed)

    /// A flat surface using the base color with no shadow, useful as a backdrop for other Neumorphism shapes.
    public static let flat = Neumorphism(variant: .flat)

    /// The base style ``SwiftUI/ButtonStyle/neumorphismProminent`` builds
    /// on: follows the ambient `tint(_:)` view modifier, with the outer
    /// glow's geometry tuned for typical button sizes — proportionally
    /// stronger and tighter than a card's, to stay visible at that scale.
    static var buttonBase: Neumorphism {
        var style = Neumorphism.regular
        style.followsAmbientTint = true
        style.outerGlowPadding = 6
        style.outerGlowOffset = 7
        style.outerGlowBlur = 4
        return style
    }

    /// The base style ``SwiftUI/ButtonStyle/neumorphism`` builds on: the
    /// mirror image of ``buttonBase`` — keeps the default (untinted)
    /// surface color instead of following the ambient `tint(_:)` view
    /// modifier, since that style colors the label text instead of the
    /// surface. Shares the same outer glow geometry, tuned for typical
    /// button sizes.
    static var neutralButtonBase: Neumorphism {
        var style = Neumorphism.regular
        style.outerGlowPadding = 6
        style.outerGlowOffset = 7
        style.outerGlowBlur = 4
        return style
    }

    /// The base style ``SwiftUI/ControlGroupStyle/neumorphism`` builds
    /// each of its segments on: a raised (convex) surface with the outer
    /// glow's geometry tightened well past ``neutralButtonBase``. A
    /// control group packs several of these segments only a small
    /// margin apart, and at that button-sized glow footprint neighboring
    /// segments' glows overlapped in the gap between them, reading as a
    /// stray dark seam rather than two independent bumps — the same
    /// reason ``switchTrackBase``/``switchKnobBase`` tighten theirs past
    /// a full-size button's.
    static var controlGroupSegmentBase: Neumorphism {
        var style = Neumorphism.neutralButtonBase
        style.outerGlowPadding = 3
        style.outerGlowOffset = 3
        style.outerGlowBlur = 2
        return style
    }

    /// The base style ``SwiftUI/ToggleStyle/neumorphismSwitch`` builds its
    /// track on: a pressed (concave) surface with the outer glow's geometry
    /// tightened further than ``buttonBase``, since a switch track is
    /// smaller still.
    static var switchTrackBase: Neumorphism {
        var style = Neumorphism.pressed
        style.outerGlowPadding = 3
        style.outerGlowOffset = 3
        style.outerGlowBlur = 2
        return style
    }

    /// The base style ``SwiftUI/ToggleStyle/neumorphismSwitch`` builds its
    /// knob on: a raised (convex) surface with the outer glow's geometry
    /// tightened to match the knob's small size. Fixed white regardless of
    /// light/dark mode, the same way the system switch's own knob never
    /// switches to a dark color in Dark Mode.
    static var switchKnobBase: Neumorphism {
        var style = Neumorphism.regular.tint(.white)
        style.outerGlowPadding = 2
        style.outerGlowOffset = 2
        style.outerGlowBlur = 1.5
        return style
    }

    /// The base style unchecked ``SwiftUI/ToggleStyle/neumorphismCheckbox``
    /// boxes use: a pressed (concave) surface with the outer glow's
    /// geometry tightened to match a checkbox's small size, keeping the
    /// default (untinted) surface color.
    static var checkboxBase: Neumorphism {
        var style = Neumorphism.pressed
        style.outerGlowPadding = 1.5
        style.outerGlowOffset = 1.5
        style.outerGlowBlur = 1
        return style
    }

    /// The base style checked ``SwiftUI/ToggleStyle/neumorphismCheckbox``
    /// boxes use: ``checkboxBase`` filled with a fixed blue rather than
    /// the ambient `tint(_:)` view modifier — the same reasoning as
    /// ``SwiftUI/ToggleStyle/neumorphismSwitch``'s fixed green: a clear,
    /// consistent "on" color instead of one that could vary per app.
    static var checkedCheckboxBase: Neumorphism {
        Neumorphism.checkboxBase.tint(.blue)
    }

    /// The base style ``SwiftUI/ProgressViewStyle/neumorphismLinear`` builds its
    /// track on: a pressed (concave) surface with the outer glow's
    /// geometry tightened to match a slim progress bar, keeping the
    /// default (untinted) surface color.
    static var progressTrackBase: Neumorphism {
        var style = Neumorphism.pressed
        style.outerGlowPadding = 1.5
        style.outerGlowOffset = 1.5
        style.outerGlowBlur = 1
        return style
    }

    /// The base style ``NeumorphismCircularGaugeStyle``'s open ring track
    /// builds on: ``progressTrackBase`` with a vertical (rather than
    /// diagonal) inner shadow — see ``shadowOffset``. Not reused by
    /// ``NeumorphismCircularProgressViewStyle``'s own, always-*full*
    /// ring, since that shape has no gap calling attention to the
    /// diagonal offset's broken symmetry the way this one's does.
    static var gaugeRingTrackBase: Neumorphism {
        var style = Neumorphism.progressTrackBase
        style.shadowOffset = CGSize(width: 0, height: 3)
        return style
    }

    /// The base style ``SwiftUI/ProgressViewStyle/neumorphismLinear`` builds its
    /// fill on: a raised (convex) surface, following the ambient
    /// `tint(_:)` view modifier the same way a system progress bar's fill
    /// follows the accent color, with the outer glow's geometry tightened
    /// to match.
    static var progressFillBase: Neumorphism {
        var style = Neumorphism.regular
        style.followsAmbientTint = true
        style.outerGlowPadding = 1.5
        style.outerGlowOffset = 1.5
        style.outerGlowBlur = 1
        return style
    }

    /// Returns a copy of the style using the given surface color instead of the default light gray.
    ///
    /// Setting an explicit tint here always wins. If you never call this,
    /// ``SwiftUI/ButtonStyle/neumorphism`` instead follows the ambient
    /// `tint(_:)` view modifier (or the app's accent color), the same way
    /// `borderedProminent` does.
    public func tint(_ color: Color) -> Neumorphism {
        var copy = self
        copy.tintColor = color
        copy.isTintCustomized = true
        return copy
    }

    /// Returns a copy of the style using the given light-source and dark-source shadow colors instead of ones automatically derived from the surface color.
    public func shadowColors(light: Color, dark: Color) -> Neumorphism {
        var copy = self
        copy.customLightSource = light
        copy.customDarkSource = dark
        return copy
    }

    /// Returns a copy of the style with its shadow opacity scaled by `value`.
    public func intensity(_ value: Double) -> Neumorphism {
        var copy = self
        copy.intensity = value
        return copy
    }

    /// Returns a copy of the style whose highlight is brightened using HDR exposure, keeping the raised edge visible against a light background instead of it blending away into low-contrast white-on-white.
    ///
    /// The extra brightness only shows up on displays with HDR headroom;
    /// standard-range displays tone-map the color back down, so the
    /// highlight never looks worse than a plain white one.
    ///
    /// - Parameter stops: How many exposure stops brighter than the
    ///   configured highlight color to render. ``regular`` and ``pressed``
    ///   already use `1`. Pass `0` to turn the glow off.
    public func glow(_ stops: Double = 1) -> Neumorphism {
        var copy = self
        copy.glowStops = stops
        return copy
    }

    var pressedVariant: Neumorphism {
        var copy = self
        copy.variant = .pressed
        return copy
    }

    /// How pressed-in the style is at rest: `0` for `.raised`, `1` for `.pressed`. Callers that animate toward a pressed touch state blend continuously toward `1` from here instead of jumping straight to it.
    var restingPressAmount: Double {
        variant == .pressed ? 1 : 0
    }

    /// The fill to draw behind the shape. Follows the ambient `tint(_:)`
    /// view modifier when ``followsAmbientTint`` is set and no explicit tint
    /// was configured; otherwise keeps the configured color.
    ///
    /// A concrete `tintColor` is resolved into a fixed RGB `Color` right
    /// here, against SwiftUI's own `environment` rather than left as a
    /// dynamic `Color(uiColor:)`/`Color(nsColor:)` for the renderer to
    /// resolve later: a dynamic system color's own light/dark switching
    /// can get corrupted by an unrelated native control appearing
    /// elsewhere in the same render pass — observed with an indeterminate
    /// `ProgressView()`, which forces every dynamic color rendered
    /// alongside it that frame to resolve against the real system
    /// appearance instead of the current SwiftUI `colorScheme` (visible as
    /// a Light Mode surface suddenly rendering black). Resolving eagerly
    /// through `Color.resolve(in:)`, which reads SwiftUI's environment
    /// directly, sidesteps that entirely. Ambient `.tint` is left alone
    /// since it isn't a system dynamic color and hasn't shown this issue.
    func resolvedFill(in environment: EnvironmentValues) -> AnyShapeStyle {
        if isTintCustomized || !followsAmbientTint {
            let resolved = tintColor.resolve(in: environment)
            return AnyShapeStyle(
                Color(
                    red: Double(resolved.red),
                    green: Double(resolved.green),
                    blue: Double(resolved.blue),
                    opacity: Double(resolved.opacity)
                )
            )
        }
        return AnyShapeStyle(.tint)
    }
}

private struct NeumorphismBackgroundKey: EnvironmentKey {
    static let defaultValue = Neumorphism.defaultTint
}

extension EnvironmentValues {
    /// The color a Neumorphism surface's outer glow is computed against.
    /// ``SwiftUI/View/neumorphismEffect(_:in:)`` registers its own resolved
    /// fill here for its content, so a surface nested inside another one
    /// automatically casts its glow against the *enclosing* surface's real
    /// color instead of a fixed neutral gray — no separate modifier needed.
    /// Defaults to ``Neumorphism/defaultTint`` outside of any such nesting.
    var neumorphismBackground: Color {
        get { self[NeumorphismBackgroundKey.self] }
        set { self[NeumorphismBackgroundKey.self] = newValue }
    }
}

