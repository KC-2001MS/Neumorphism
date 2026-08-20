import SwiftUI

/// A progress view style that renders as a Neumorphism-styled ring: a
/// circular, concave (pressed) track that a partial-circle, convex
/// (raised) arc fills in as progress advances. The Neumorphism
/// counterpart to `CircularProgressViewStyle`, constructed via
/// ``SwiftUI/ProgressViewStyle/circular``.
///
/// ```swift
/// ProgressView(value: progress)
///     .progressViewStyle(.neumorphismCircular)
/// ```
///
/// Compared against the real `.circular` style directly: the ring comes
/// first, with the label and then the current-value label stacked below
/// it — unlike ``NeumorphismLinearProgressViewStyle``, where the label
/// sits above the bar and the current-value label below it. The fill
/// follows the ambient `tint(_:)` view modifier (or the app's accent
/// color), the same way a system progress ring's fill does. When the
/// progress is indeterminate (no `value` was given), the same
/// percentage-driven fill is reused, just fed a fraction that keeps
/// growing from `0` to `1` and resetting, instead of a real value —
/// rather than the system's own spinning-lines indicator, which has no
/// equivalent "fraction" to reuse.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct NeumorphismCircularProgressViewStyle: ProgressViewStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 6) {
            NeumorphismCircularProgressRing(fractionCompleted: configuration.fractionCompleted)
            configuration.label
            configuration.currentValueLabel
        }
    }
}

/// The track and fill of a ``NeumorphismCircularProgressViewStyle`` ring,
/// as its own named view for the same reason
/// ``NeumorphismProminentButtonStyle`` splits its label out: a stable
/// identity for the fill to animate in place as `fractionCompleted`
/// changes.
private struct NeumorphismCircularProgressRing: View {
    var fractionCompleted: Double?

    private let diameter: CGFloat = 56
    private let trackLineWidth: CGFloat = 10
    // A gap between the fill and the track's own edges, the same way
    // `NeumorphismLinearProgressViewStyle`'s fill floats inset within
    // its track rather than sitting flush against it.
    private let inset: CGFloat = 2.5

    var body: some View {
        let fillDiameter = diameter - inset * 2
        let fillLineWidth = trackLineWidth - inset * 2
        ZStack {
            Color.clear
                .frame(width: diameter, height: diameter)
                .neumorphismEffect(Neumorphism.progressTrackBase, in: NeumorphismRingShape(lineWidth: trackLineWidth))
            if let fractionCompleted {
                NeumorphismCircularFill(diameter: fillDiameter, lineWidth: fillLineWidth, fraction: fractionCompleted)
                    .animation(.easeOut(duration: 0.2), value: fractionCompleted)
            } else {
                NeumorphismCircularIndeterminateFill(diameter: fillDiameter, lineWidth: fillLineWidth)
            }
        }
    }
}

/// The fill of a ``NeumorphismCircularProgressViewStyle`` ring, sized to
/// `fraction` (`0`...`1`) of a full turn, starting at 12 o'clock and
/// sweeping clockwise. Both the determinate case (`fractionCompleted`)
/// and the indeterminate case (a fraction that keeps growing and
/// resetting, see ``NeumorphismCircularIndeterminateFill``) go through
/// this same view — the same reasoning as
/// ``NeumorphismLinearProgressViewStyle``'s shared fill.
private struct NeumorphismCircularFill: View {
    var diameter: CGFloat
    var lineWidth: CGFloat
    var fraction: Double

    var body: some View {
        let effectiveFraction = max(0.02, min(1, max(0, fraction)))
        Color.clear
            .frame(width: diameter, height: diameter)
            .neumorphismEffect(Neumorphism.progressFillBase, in: NeumorphismArcShape(lineWidth: lineWidth, fraction: effectiveFraction))
            // The fill and the track are siblings, not ancestor/descendant,
            // so the track's own registration of `neumorphismBackground`
            // never reaches the fill — see the same fix on
            // `NeumorphismSwitchToggleStyle`'s knob.
            .environment(\.neumorphismBackground, Neumorphism.defaultTint)
    }
}

/// The indeterminate case of ``NeumorphismCircularFill``: no `value` was
/// given to the `ProgressView`, so this drives the same fraction-based
/// arc with a fraction that repeatedly grows from `0` to `1` and resets,
/// rather than a real value.
///
/// Driven by `TimelineView` rather than `withAnimation(...).repeatForever(...)`:
/// an indefinitely-repeating animation transaction was observed to corrupt
/// how *every* dynamic system color (like ``Neumorphism/defaultTint``)
/// resolves for the rest of that render pass — see the identical note on
/// `NeumorphismLinearIndeterminateFill`.
private struct NeumorphismCircularIndeterminateFill: View {
    var diameter: CGFloat
    var lineWidth: CGFloat

    private let period: Double = 1.4

    var body: some View {
        TimelineView(.animation) { context in
            let fraction = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: period) / period
            NeumorphismCircularFill(diameter: diameter, lineWidth: lineWidth, fraction: fraction)
        }
    }
}

/// A full annulus (ring) shape, `lineWidth` thick, inscribed in the given
/// rect — built from two opposite-wound circles so the interior, unlike
/// a plain `Circle`, is hollow.
private struct NeumorphismRingShape: Shape {
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = max(outerRadius - lineWidth, 0)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
        return path
    }
}

/// A partial annulus (ring segment), `lineWidth` thick, starting at 12
/// o'clock and sweeping clockwise for `fraction` (`0`...`1`) of a full
/// turn — the filled counterpart to ``NeumorphismRingShape``.
private struct NeumorphismArcShape: Shape {
    var lineWidth: CGFloat
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // Built from a single-radius arc *line*, converted to its own
        // stroked outline (rather than a filled pie-slice-ring made of
        // two arcs joined by a flat radial cut), so the two ends round
        // off like `StrokeStyle.lineCap.round` instead of coming to a
        // sharp point.
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle.degrees(-90)
        let endAngle = Angle.degrees(-90 + 360 * min(1, max(0, fraction)))
        var centerline = Path()
        centerline.addArc(center: center, radius: max(radius, 0), startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return centerline.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ProgressViewStyle where Self == NeumorphismCircularProgressViewStyle {
    /// A progress view style that renders as a Neumorphism-styled ring.
    public static var neumorphismCircular: NeumorphismCircularProgressViewStyle {
        NeumorphismCircularProgressViewStyle()
    }
}

#Preview("Circular") {
    HStack(spacing: 40) {
        ProgressView(value: 0.3)
            .progressViewStyle(.neumorphismCircular)

        ProgressView(value: 0.7)
            .progressViewStyle(.neumorphismCircular)
            .tint(.pink)

        ProgressView("Downloading…", value: 0.5)
            .progressViewStyle(.neumorphismCircular)

        ProgressView()
            .progressViewStyle(.neumorphismCircular)
    }
    .padding(60)
}
