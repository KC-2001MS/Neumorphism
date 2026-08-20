import SwiftUI

/// A gauge style that renders as a Neumorphism-styled closed ring that's
/// partially filled in, starting at 12 o'clock and sweeping clockwise,
/// to indicate the gauge's current value. The Neumorphism counterpart to
/// `AccessoryCircularCapacityGaugeStyle`, constructed via
/// ``SwiftUI/GaugeStyle/neumorphismAccessoryCircularCapacity``.
///
/// ```swift
/// Gauge(value: batteryLevel, in: 0...100) {
///     Text("Battery Level")
/// }
/// .gaugeStyle(.neumorphismAccessoryCircularCapacity)
/// ```
///
/// Unlike ``NeumorphismCircularGaugeStyle``/``NeumorphismAccessoryCircularGaugeStyle``,
/// whose ring stays fully open with just a marker riding along it, this
/// ring is fully closed — its own concave track shows the whole circle
/// at rest, the same way ``NeumorphismCircularProgressViewStyle``'s
/// track does, and the raised fill sweeps around it to show the current
/// value.
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
public struct NeumorphismAccessoryCircularCapacityGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 6) {
            NeumorphismGaugeCapacityRing(fraction: configuration.value)
            configuration.label
            configuration.currentValueLabel
        }
    }
}

/// The track and fill of a
/// ``NeumorphismAccessoryCircularCapacityGaugeStyle`` ring, as its own
/// named view for the same reason ``NeumorphismProminentButtonStyle``
/// splits its label out: a stable identity for the fill to animate in
/// place as `fraction` changes.
private struct NeumorphismGaugeCapacityRing: View {
    var fraction: Double

    private let diameter: CGFloat = 56
    private let trackLineWidth: CGFloat = 10
    // A gap between the fill and the track's own edges, the same way
    // `NeumorphismCircularProgressViewStyle`'s fill floats inset within
    // its track rather than sitting flush against it.
    private let inset: CGFloat = 2.5

    var body: some View {
        let fillDiameter = diameter - inset * 2
        let fillLineWidth = trackLineWidth - inset * 2
        let effectiveFraction = max(0.02, min(1, max(0, fraction)))
        ZStack {
            Color.clear
                .frame(width: diameter, height: diameter)
                .neumorphismEffect(Neumorphism.progressTrackBase, in: NeumorphismGaugeClosedRingShape(lineWidth: trackLineWidth))
            Color.clear
                .frame(width: fillDiameter, height: fillDiameter)
                .neumorphismEffect(Neumorphism.progressFillBase, in: NeumorphismGaugeCapacityArcShape(lineWidth: fillLineWidth, fraction: effectiveFraction))
                // The fill and the track are siblings, not
                // ancestor/descendant, so the track's own registration of
                // `neumorphismBackground` never reaches the fill — see
                // the same fix on `NeumorphismSwitchToggleStyle`'s knob.
                .environment(\.neumorphismBackground, Neumorphism.defaultTint)
                .animation(.easeOut(duration: 0.2), value: fraction)
        }
    }
}

/// A full annulus (ring) shape, `lineWidth` thick, inscribed in the given
/// rect — the track counterpart to ``NeumorphismGaugeCapacityArcShape``.
private struct NeumorphismGaugeClosedRingShape: Shape {
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
/// turn, with rounded ends — the filled counterpart to
/// ``NeumorphismGaugeClosedRingShape``.
private struct NeumorphismGaugeCapacityArcShape: Shape {
    var lineWidth: CGFloat
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // Built from a single-radius arc *line*, converted to its own
        // stroked outline, so the two ends round off like
        // `StrokeStyle.lineCap.round` instead of coming to a sharp point
        // — see the identical technique in
        // `NeumorphismCircularProgressViewStyle`.
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle.degrees(-90)
        let endAngle = Angle.degrees(-90 + 360 * min(1, max(0, fraction)))
        var centerline = Path()
        centerline.addArc(center: center, radius: max(radius, 0), startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return centerline.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
extension GaugeStyle where Self == NeumorphismAccessoryCircularCapacityGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled closed, partially-filled ring.
    public static var neumorphismAccessoryCircularCapacity: NeumorphismAccessoryCircularCapacityGaugeStyle {
        NeumorphismAccessoryCircularCapacityGaugeStyle()
    }
}

// `Gauge`/`GaugeStyleConfiguration` don't exist in the tvOS SDK at all,
// so this preview can't build for that platform's canvas.
#if !os(tvOS)
#Preview("Accessory Circular Capacity") {
    HStack(spacing: 40) {
        Gauge(value: 0.4, in: 0...1) {
            Text("Speed")
        } currentValueLabel: {
            Text("40%")
        }
        .gaugeStyle(.neumorphismAccessoryCircularCapacity)

        Gauge(value: 0.8, in: 0...1) {
            Text("Volume")
        }
        .gaugeStyle(.neumorphismAccessoryCircularCapacity)
        .tint(.pink)
    }
    .padding(60)
}
#endif
