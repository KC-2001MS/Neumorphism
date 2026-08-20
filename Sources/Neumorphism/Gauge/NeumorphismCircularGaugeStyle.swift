import SwiftUI

/// A gauge style that renders as a Neumorphism-styled open ring with a
/// small raised marker at a point along the ring indicating the gauge's
/// current value. The Neumorphism counterpart to `CircularGaugeStyle`,
/// constructed via ``SwiftUI/GaugeStyle/circular``.
///
/// ```swift
/// Gauge(value: current, in: 0...170) {
///     Text("BPM")
/// } currentValueLabel: {
///     Text("\(Int(current))")
/// }
/// .gaugeStyle(.neumorphismCircular)
/// ```
///
/// `GaugeStyle.circular` itself isn't available on macOS, but
/// `GaugeStyle.accessoryCircular` — documented as sharing the same
/// appearance — is, and rendering it directly showed the
/// `currentValueLabel`/`label` stacking *inside* the ring rather than
/// below it, which is fixed to match. The gap itself sits at the
/// *bottom* of the ring, the conventional open-dial orientation.
///
/// `circular` itself is watchOS-only (introduced in watchOS 7, and
/// explicitly unavailable everywhere else) — this mirrors that exact
/// restriction rather than leaving it usable wherever this package
/// happens to compile, the same way ``NeumorphismCheckboxToggleStyle``
/// mirrors `CheckboxToggleStyle` being macOS-only.
@available(watchOS 7.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(visionOS, unavailable)
public struct NeumorphismCircularGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        neumorphismGaugeRingBody(configuration: configuration)
    }
}

/// The shared rendering behind ``NeumorphismCircularGaugeStyle``,
/// ``NeumorphismAccessoryCircularGaugeStyle``, and
/// ``NeumorphismDefaultGaugeStyle``: kept as a free function rather than
/// having the latter two delegate to `NeumorphismCircularGaugeStyle`'s
/// own `makeBody(configuration:)` (the way most of this package's
/// "shares its appearance with" styles delegate) because that style is
/// watchOS-only, while both callers need to stay available on iOS and
/// macOS too — delegating to a more narrowly available style would make
/// the wider one uncompilable there.
///
/// `@available` here matches `GaugeStyleConfiguration` itself (the
/// parameter type): unlike most of this package's other
/// `@available(tvOS, unavailable)` annotations, which just restrict an
/// otherwise-present API, `Gauge`/`GaugeStyleConfiguration` don't exist
/// in the tvOS SDK at all, so this needs its own explicit restriction
/// rather than inheriting one from an enclosing, already-restricted type.
@available(iOS 16.0, macOS 13.0, watchOS 7.0, *)
@available(tvOS, unavailable)
@MainActor
func neumorphismGaugeRingBody(configuration: GaugeStyleConfiguration) -> some View {
    NeumorphismGaugeRing(fraction: configuration.value) {
        // Rendering the real `.accessoryCircular` style directly
        // showed `currentValueLabel` set noticeably larger than
        // `label` — not the same small size this used before —
        // large enough that it (and `label`, hanging below it) run
        // past the ring's own inner edge and over the track itself
        // rather than staying confined to the hole.
        configuration.currentValueLabel
            .font(.system(size: 20, weight: .semibold))
            .alignmentGuide(.gaugeCurrentValue) { $0[VerticalAlignment.center] }
        configuration.label
            .font(.system(size: 9))
    }
}

/// The track, marker, and inline labels of a
/// ``NeumorphismCircularGaugeStyle`` ring, as its own named view for the
/// same reason ``NeumorphismProminentButtonStyle`` splits its label out:
/// a stable identity for the marker to animate in place as `fraction`
/// changes.
struct NeumorphismGaugeRing<Labels: View>: View {
    var fraction: Double
    var labels: Labels

    init(fraction: Double, @ViewBuilder labels: () -> Labels) {
        self.fraction = fraction
        self.labels = labels()
    }

    private let diameter: CGFloat = 64
    // Measured directly from the real `.accessoryCircular` style: its
    // ring is about 17% of the overall diameter thick, not the ~31% this
    // used before — that earlier, much thicker ring left almost no room
    // for the inline labels, which is what made this style look so far
    // off from the original.
    private let trackLineWidth: CGFloat = 11
    private let margin: CGFloat = 2
    private var markerDiameter: CGFloat { trackLineWidth - margin * 2 }
    // Leaves a gap open at the *bottom* of the dial, the conventional
    // orientation for an open circular gauge/dial (the same reason a
    // Landolt C's gap reads as "correct" at the bottom, not the top):
    // rendering the real `.accessoryCircular` style directly was
    // misread earlier as putting the gap at the top.
    private let startAngle = Angle.degrees(125)
    private let sweepAngle = Angle.degrees(290)

    var body: some View {
        let clampedFraction = min(1, max(0, fraction))
        let markerAngle = startAngle + sweepAngle * clampedFraction
        let radius = diameter / 2 - trackLineWidth / 2
        // Wide enough that `currentValueLabel` is free to run past the
        // ring's own inner edge and over the track, matching the real
        // `.accessoryCircular` style — only `minimumScaleFactor` below
        // guards against a much longer, custom label overflowing the
        // control entirely.
        let labelWidth = diameter - 4
        ZStack(alignment: Alignment(horizontal: .center, vertical: .gaugeCurrentValue)) {
            Color.clear
                .frame(width: diameter, height: diameter)
                .neumorphismEffect(
                    Neumorphism.gaugeRingTrackBase,
                    in: NeumorphismGaugeRingShape(lineWidth: trackLineWidth, startAngle: startAngle, sweepAngle: sweepAngle)
                )
            Color.clear
                .frame(width: markerDiameter, height: markerDiameter)
                .neumorphismEffect(Neumorphism.progressFillBase, in: Circle())
                // The marker and the track are siblings, not
                // ancestor/descendant, so the track's own registration of
                // `neumorphismBackground` never reaches the marker — see
                // the same fix on `NeumorphismSwitchToggleStyle`'s knob.
                .environment(\.neumorphismBackground, Neumorphism.defaultTint)
                .offset(x: radius * CGFloat(cos(markerAngle.radians)), y: radius * CGFloat(sin(markerAngle.radians)))
                .animation(.easeOut(duration: 0.2), value: fraction)
            // Rendering it directly showed the real `.accessoryCircular`
            // style doesn't center this whole two-line block in the
            // ring the way a plain `VStack` would here: it keeps
            // `currentValueLabel` itself dead-centered, with `label`
            // simply hanging below — pulling the block's overall center
            // noticeably lower than a `VStack`'s own would sit. The
            // custom `.gaugeCurrentValue` guide reports the ZStack's
            // ordinary center for every other child (the ring, the
            // marker) but is overridden below to track just
            // `currentValueLabel`'s own center instead, so aligning the
            // whole stack to it reproduces that same offset.
            VStack(spacing: 1) {
                labels
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(width: labelWidth)
        }
    }
}

extension VerticalAlignment {
    private struct GaugeCurrentValueAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }

    static let gaugeCurrentValue = VerticalAlignment(GaugeCurrentValueAlignment.self)
}

/// An open annulus (ring with a gap), `lineWidth` thick, starting at
/// `startAngle` and spanning `sweepAngle` — the track counterpart to
/// ``NeumorphismCircularProgressViewStyle``'s always-full ring.
private struct NeumorphismGaugeRingShape: Shape {
    var lineWidth: CGFloat
    var startAngle: Angle
    var sweepAngle: Angle

    func path(in rect: CGRect) -> Path {
        // Built from a single centerline arc, stroked with a round cap
        // — the same technique `NeumorphismCircularProgressViewStyle`'s
        // own arc fill uses — rather than two opposite-wound arcs joined
        // into a flat-cut band. The round-cap version was tried first
        // and rejected because it produced a self-crossing,
        // pinwheel-shaped outline, but that break only happened at the
        // old, much thicker `lineWidth` (20pt on a 64pt diameter): the
        // cap's radius was too large a fraction of the ring's own
        // radius. At the corrected, thinner track width the cap traces
        // cleanly, and it also matches every other rounded cap used in
        // this package (e.g. the progress ring's fill).
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var centerline = Path()
        centerline.addArc(center: center, radius: max(radius, 0), startAngle: startAngle, endAngle: startAngle + sweepAngle, clockwise: false)
        return centerline.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

@available(watchOS 7.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(visionOS, unavailable)
extension GaugeStyle where Self == NeumorphismCircularGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled open ring with a marker.
    public static var neumorphismCircular: NeumorphismCircularGaugeStyle {
        NeumorphismCircularGaugeStyle()
    }
}

// `.circular` (and this counterpart) only exist on watchOS, so this
// preview can't build for any other platform's canvas.
#if os(watchOS)
#Preview("Circular Marker") {
    HStack(spacing: 40) {
        Gauge(value: 0.4, in: 0...1) {
            Text("Speed")
        } currentValueLabel: {
            Text("40%")
        }
        .gaugeStyle(.circular)

        Gauge(value: 0.4, in: 0...1) {
            Text("Speed")
        } currentValueLabel: {
            Text("40%")
        }
        .gaugeStyle(.neumorphismCircular)
        .tint(.pink)
    }
    .padding(60)
}
#endif
