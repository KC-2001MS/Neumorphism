import SwiftUI

/// A gauge style that renders as a Neumorphism-styled bar with a small
/// raised marker at a point along the track indicating the gauge's
/// current value — unlike ``NeumorphismLinearCapacityGaugeStyle``, the
/// track itself never fills with color. The Neumorphism counterpart to
/// `LinearGaugeStyle`, constructed via ``SwiftUI/GaugeStyle/linear``.
///
/// ```swift
/// Gauge(value: speed, in: 0...200) {
///     Text("Speed")
/// }
/// .gaugeStyle(.neumorphismLinear)
/// ```
///
/// `GaugeStyle.linear` isn't available on macOS, so this was built from
/// its documented behavior rather than a direct on-screen comparison —
/// double check the marker's placement on iOS/watchOS if precision
/// matters there. The overall layout otherwise follows
/// ``NeumorphismLinearCapacityGaugeStyle``, which *was* confirmed
/// directly against the real `.linearCapacity` style: `label` above,
/// `currentValueLabel` below, `minimumValueLabel`/`maximumValueLabel`
/// flanking the track.
///
/// `linear` itself is watchOS-only (the same restriction `circular`
/// has, for the same reason) — mirrored here rather than left usable
/// wherever this package happens to compile.
@available(watchOS 7.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(visionOS, unavailable)
public struct NeumorphismLinearGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        neumorphismGaugeLinearMarkerBody(configuration: configuration)
    }
}

/// The shared rendering behind ``NeumorphismLinearGaugeStyle`` and
/// ``NeumorphismAccessoryLinearGaugeStyle``: kept as a free function
/// rather than having the latter delegate to
/// `NeumorphismLinearGaugeStyle`'s own `makeBody(configuration:)`, the
/// same reason ``neumorphismGaugeRingBody(configuration:)`` exists
/// instead of routing through `NeumorphismCircularGaugeStyle`'s —
/// `LinearGaugeStyle` is watchOS-only, while `AccessoryLinearGaugeStyle`
/// also needs iOS and macOS.
///
/// `@available` here matches `GaugeStyleConfiguration` itself — see the
/// identical note on ``neumorphismGaugeRingBody(configuration:)``.
@available(iOS 16.0, macOS 13.0, watchOS 7.0, *)
@available(tvOS, unavailable)
@MainActor
func neumorphismGaugeLinearMarkerBody(configuration: GaugeStyleConfiguration) -> some View {
    VStack(spacing: 6) {
        configuration.label
        HStack(spacing: 8) {
            configuration.minimumValueLabel
            NeumorphismGaugeLinearMarkerTrack(fraction: configuration.value)
            configuration.maximumValueLabel
        }
        configuration.currentValueLabel
    }
}

/// The track and marker of a ``NeumorphismLinearGaugeStyle`` bar, as its
/// own named view for the same reason ``NeumorphismProminentButtonStyle``
/// splits its label out: a stable identity for the marker to animate in
/// place as `fraction` changes.
struct NeumorphismGaugeLinearMarkerTrack: View {
    var fraction: Double

    // The track needs to be thick enough that a marker inset within it
    // by `margin` on every side (the same way
    // `NeumorphismSwitchToggleStyle`'s knob floats inset within its
    // track) still reads as a legible circle, rather than the marker
    // just overflowing past the track's own edges.
    private let height: CGFloat = 22
    private let margin: CGFloat = 3
    private var markerDiameter: CGFloat { height - margin * 2 }

    var body: some View {
        GeometryReader { proxy in
            let clampedFraction = min(1, max(0, fraction))
            let travel = max(0, proxy.size.width - height)
            ZStack(alignment: .leading) {
                Color.clear
                    .neumorphismEffect(Neumorphism.progressTrackBase, in: Capsule())
                Color.clear
                    .frame(width: markerDiameter, height: markerDiameter)
                    .neumorphismEffect(Neumorphism.progressFillBase, in: Circle())
                    // The marker and the track are siblings, not
                    // ancestor/descendant, so the track's own registration
                    // of `neumorphismBackground` never reaches the marker
                    // — see the same fix on
                    // `NeumorphismSwitchToggleStyle`'s knob.
                    .environment(\.neumorphismBackground, Neumorphism.defaultTint)
                    .padding(margin)
                    .offset(x: travel * CGFloat(clampedFraction))
                    .animation(.easeOut(duration: 0.2), value: fraction)
            }
        }
        .frame(height: height)
    }
}

@available(watchOS 7.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(visionOS, unavailable)
extension GaugeStyle where Self == NeumorphismLinearGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled bar with a marker.
    public static var neumorphismLinear: NeumorphismLinearGaugeStyle {
        NeumorphismLinearGaugeStyle()
    }
}

// `.linear` (and this counterpart) only exist on watchOS, so this
// preview can't build for any other platform's canvas.
#if os(watchOS)
#Preview("Linear Marker") {
    VStack(spacing: 30) {
        Gauge(value: 0.4, in: 0...1) {
            Text("Speed")
        } currentValueLabel: {
            Text("40%")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
        .gaugeStyle(.neumorphismLinear)

        Gauge(value: 0.8, in: 0...1) {
            Text("Volume")
        }
        .gaugeStyle(.neumorphismLinear)
        .tint(.pink)
    }
    .padding(60)
}
#endif
