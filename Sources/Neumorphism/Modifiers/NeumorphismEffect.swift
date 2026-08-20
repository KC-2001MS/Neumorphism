import SwiftUI

private struct NeumorphismEffect<S: Shape>: ViewModifier {
    var style: Neumorphism
    var shape: S

    @Environment(\.self) private var environment

    func body(content: Content) -> some View {
        let pressAmount = style.restingPressAmount
        let raisedAmount = 1 - pressAmount

        // An ambient tint (buttons only, via `followsAmbientTint`) never
        // resolves to a concrete `Color` in Swift code — same as `.tint`
        // on any built-in button style, the renderer substitutes the real
        // color at draw time — so there's no brightness/saturation to read
        // for the adaptive boosts below in that case.
        let isFillColorKnown = !(style.followsAmbientTint && !style.isTintCustomized)
        let innerBoosts = style.innerContrastBoosts(in: environment, isFillColorKnown: isFillColorKnown)
        let outerBoosts = Neumorphism.contrastBoosts(of: environment.neumorphismBackground, in: environment)

        let fill = style.resolvedFill(in: environment)

        // Pressed softens the outer glow relative to raised: less color
        // difference from the page, spread over a wider blur, so the
        // pressed state's rim reads as a gentler, more gradual falloff
        // instead of the crisper, higher-contrast one a fully raised
        // surface uses. The shadow-casting shape's own size (padding) stays
        // fixed rather than also growing with `pressAmount`: shrinking it
        // less makes more of it peek out from behind the content, and that
        // was fighting the simultaneously dropping opacity — at some
        // in-between `pressAmount` the bigger-but-not-yet-very-transparent
        // shape actually read darker than either the raised or pressed
        // endpoint, an overshoot visible mid-animation. Leaving padding
        // fixed removes that interaction.
        let outerGlowDelta = 0.25 - 0.15 * pressAmount
        let outerGlowBlurAmount = style.outerGlowBlur + 8 * pressAmount
        let outerGlowPaddingAmount = style.outerGlowPadding
        let outerLightSource = Neumorphism.outerLightSource(in: environment, delta: outerGlowDelta)
        let outerDarkSource = Neumorphism.outerDarkSource(in: environment, delta: outerGlowDelta)

        let nearX = style.shadowOffset.width
        let nearY = style.shadowOffset.height
        let farX = -style.shadowOffset.width
        let farY = -style.shadowOffset.height

        // Mostly the surface's own color with a little black mixed in, kept
        // fully opaque, rather than a separate dark color at partial
        // opacity: `ShadowStyle.inner` washes a translucent color out
        // lighter than expected, so blending toward black ourselves (and
        // letting `pressAmount`/boosts control how much black, not how
        // transparent it is) is what actually reads as a shadow. Only valid
        // when the fill's own color is known — this is why the ambient case
        // below can't reuse it, quite apart from having no real color to mix.
        let nearShadow = Neumorphism.mixedTowardBlack(style.tintColor, by: 0.14 * innerBoosts.shadow * style.intensity * pressAmount, in: environment)

        // The far (bottom-right) wall of the dent slopes back up toward the
        // same top-left light the outer glow implies, so it catches that
        // light rather than falling further into shadow — a highlight, not
        // a second (weaker) shadow.
        let farHighlight = Neumorphism.mixedTowardWhite(style.tintColor, by: 0.05 * innerBoosts.highlight * style.intensity * pressAmount, in: environment)

        // The raised state's counterpart to `nearShadow`, at the same wall
        // (top-left) — but toward black, not white: mixing an already-white
        // surface toward white changes nothing (there's no headroom left),
        // the same reason the outer highlight itself disappears once the
        // background is already near-white. Mixing toward black always has
        // headroom (confirmed by the pressed state's own near/far shadow
        // working fine on this same white surface), so a subtle version of
        // it here still defines the top-left edge even when a true
        // brightness-based highlight can't.
        let nearEdge = Neumorphism.mixedTowardBlack(style.tintColor, by: 0.04 * innerBoosts.shadow * style.intensity * raisedAmount, in: environment)

        // The mirror image of `nearEdge`, on the far (bottom-right) wall:
        // redundant insurance for a near-black surface, where the outer
        // shadow's own darkening would clamp to the same black it's drawn
        // against and disappear. Toward white always has headroom on a dark
        // surface (the reverse of `nearEdge`'s case), and has none at all
        // once the surface is already near-white, so this is a no-op there.
        let farEdge = Neumorphism.mixedTowardWhite(style.tintColor, by: 0.07 * innerBoosts.highlight * style.intensity * raisedAmount, in: environment)

        let clippedContent = content
            .clipShape(shape)
            .contentShape(shape)

        // Each outer glow is a blurred, shrunken, offset duplicate of the
        // same shape (so it follows the exact corner radius), sitting
        // behind the opaque content — shrinking it first keeps the glow
        // contained rather than ballooning past the shape. A masked
        // `View.shadow()` was tried first, but a shadow's blur only lives
        // in a thin band hugging the silhouette — cropping that thin
        // curved band with any mask boundary produces a pointed wedge
        // right at the corner instead of a broad, rounded glow.
        // Neither outer layer is scaled by `raisedAmount`: a pressed
        // (concave) surface still has the same lip catching the light at
        // its top-left edge, and casting the same shadow at its
        // bottom-right edge, that a raised (convex) one does — the outer
        // glow reads the same in both states, only the inner shadow chain
        // tells raised and pressed apart.
        let outerGlow = ZStack {
            shape
                .fill(outerDarkSource)
                // Pressed also dampens the dark side's own opacity, on top
                // of the softer color/blur/spread above: even with those,
                // the shadow was still reading stronger than the highlight
                // at full press.
                .opacity(0.55 * outerBoosts.shadow * style.intensity * (1 - 0.9 * pressAmount))
                .padding(outerGlowPaddingAmount)
                .offset(x: style.outerGlowOffset, y: style.outerGlowOffset)
                .blur(radius: outerGlowBlurAmount)
            shape
                .fill(outerLightSource)
                .opacity(0.9 * outerBoosts.highlight * style.intensity)
                .padding(outerGlowPaddingAmount)
                .offset(x: -style.outerGlowOffset, y: -style.outerGlowOffset)
                .blur(radius: outerGlowBlurAmount)
        }

        Group {
            if style.variant == .flat {
                clippedContent
                    .background(fill, in: shape)
            } else if isFillColorKnown {
                clippedContent
                    .background(
                        // Pressed reads as a dent lit from the top-left: a
                        // dark inner shadow on the near (top-left) wall,
                        // and a highlight on the far (bottom-right) wall,
                        // which slopes back up into that same light.
                        fill
                            .shadow(.inner(color: nearEdge, radius: 3, x: nearX, y: nearY))
                            .shadow(.inner(color: farEdge, radius: 4, x: farX, y: farY))
                            .shadow(.inner(color: nearShadow, radius: 2, x: nearX, y: nearY))
                            .shadow(.inner(color: farHighlight, radius: 1, x: farX, y: farY)),
                        in: shape
                    )
                    .background(outerGlow)
            } else {
                // The same `ShadowStyle.inner` dent as the known-color case
                // above, applied directly to the unresolved `.tint` style
                // instead of a concrete color: chaining two of these with a
                // color that's *exactly* fully transparent (as needed at
                // rest, when `pressAmount == 0`) onto an unresolved `.tint`
                // whites out the entire fill, so each color is floored to a
                // hair above zero opacity instead — invisible in practice,
                // but never literally `0`, which is what actually triggers
                // the bug.
                //
                // The raised counterpart (`nearEdge`/`farEdge` in the
                // known-color branch) can't mix toward black/white without
                // a real color to mix, so this uses the same fixed
                // black/white opacity trick instead, scaled by
                // `raisedAmount` rather than `pressAmount` — without it, an
                // ambient-tint raised surface (e.g. this progress bar's
                // fill) had no edge shading at all and read as flat rather
                // than convex.
                clippedContent
                    .background(
                        fill
                            .shadow(.inner(color: .black.opacity(max(0.003, 0.3 * style.intensity * pressAmount)), radius: 2, x: 3, y: 3))
                            .shadow(.inner(color: .white.opacity(max(0.003, 0.1 * style.intensity * pressAmount)), radius: 1, x: -3, y: -3))
                            .shadow(.inner(color: .black.opacity(max(0.003, 0.08 * style.intensity * raisedAmount)), radius: 3, x: 3, y: 3))
                            .shadow(.inner(color: .white.opacity(max(0.003, 0.12 * style.intensity * raisedAmount)), radius: 4, x: -3, y: -3)),
                        in: shape
                    )
                    .background(outerGlow)
            }
        }
        .animation(.easeOut(duration: 0.15), value: pressAmount)
        // Registers this surface's own color as the background that any
        // Neumorphism surface nested inside (or layered after, e.g. via
        // `.overlay`) computes its outer glow against — so nesting one
        // surface inside another needs no separate setup.
        .environment(\.neumorphismBackground, style.tintColor)
    }
}

extension View {
    /// Applies a Neumorphism effect to a view, matching the given shape.
    ///
    /// This plays the same role that `glassEffect(_:in:)` plays for the
    /// Liquid Glass material: pass ``Neumorphism/regular`` (the default,
    /// protruding/convex) or ``Neumorphism/pressed`` (inset/concave) the
    /// same way you'd pass `.regular` or `.clear` to `glassEffect(_:in:)`.
    /// The view is clipped to `shape` and paired light/dark shadows are
    /// rendered behind it to simulate a soft, extruded or inset surface.
    ///
    /// ```swift
    /// Text("Hello, World!")
    ///     .font(.title)
    ///     .padding()
    ///     .neumorphismEffect(.regular, in: .rect(cornerRadius: 20))
    /// ```
    ///
    /// Nest a smaller shape styled with ``Neumorphism/pressed`` inside a
    /// view styled with ``Neumorphism/regular`` to get the mixed
    /// "inset control on a raised panel" look.
    public func neumorphismEffect(
        _ style: Neumorphism = .regular,
        in shape: some Shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
    ) -> some View {
        modifier(NeumorphismEffect(style: style, shape: shape))
    }
}

#Preview("Raised") {
    Color.clear
        .frame(width: 160, height: 160)
        .neumorphismEffect(.regular)
        .padding(60)
}

#Preview("Pressed") {
    Color.clear
        .frame(width: 160, height: 160)
        .neumorphismEffect(.pressed)
        .padding(60)
}

#Preview("Mix") {
    Color.clear
        .frame(width: 200, height: 200)
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            Color.clear
                .frame(width: 120, height: 120)
                .neumorphismEffect(.pressed, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(60)
}
