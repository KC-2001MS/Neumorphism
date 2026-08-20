import SwiftUI

/// A gauge style that renders as a Neumorphism-styled bar that fills
/// from the leading to the trailing edge as the gauge's current value
/// increases. The Neumorphism counterpart to `LinearCapacityGaugeStyle`,
/// constructed via ``SwiftUI/GaugeStyle/linearCapacity``.
///
/// ```swift
/// Gauge(value: batteryLevel, in: 0...100) {
///     Text("Battery Level")
/// }
/// .gaugeStyle(.neumorphismLinearCapacity)
/// ```
///
/// Compared against the real `.linearCapacity` style directly: `label`
/// appears above the bar, `currentValueLabel` below it, and
/// `minimumValueLabel`/`maximumValueLabel` flank the bar's leading and
/// trailing edges. The fill follows the ambient `tint(_:)` view modifier
/// (or the app's accent color) and shares its track/fill rendering with
/// ``NeumorphismLinearProgressViewStyle``, since a capacity gauge is
/// fundamentally the same "fraction rendered as a width" shape a
/// progress bar is.
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
public struct NeumorphismLinearCapacityGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 6) {
            configuration.label
            HStack(spacing: 8) {
                configuration.minimumValueLabel
                NeumorphismGaugeLinearTrack(fraction: configuration.value)
                configuration.maximumValueLabel
            }
            configuration.currentValueLabel
        }
    }
}

/// The track and fill of a ``NeumorphismLinearCapacityGaugeStyle`` bar,
/// as its own named view for the same reason
/// ``NeumorphismProminentButtonStyle`` splits its label out: a stable
/// identity for the fill to animate in place as `fraction` changes.
private struct NeumorphismGaugeLinearTrack: View {
    var fraction: Double

    private let height: CGFloat = 16
    // A gap between the fill and the track's own edges, the same way
    // `NeumorphismLinearProgressViewStyle`'s fill floats inset within
    // its track rather than sitting flush against it.
    private let inset: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let innerWidth = proxy.size.width - inset * 2
            let innerHeight = height - inset * 2
            let fillWidth = max(innerHeight, innerWidth * CGFloat(min(1, max(0, fraction))))
            ZStack(alignment: .leading) {
                Color.clear
                    .neumorphismEffect(Neumorphism.progressTrackBase, in: Capsule())
                Color.clear
                    .frame(width: fillWidth, height: innerHeight)
                    .neumorphismEffect(Neumorphism.progressFillBase, in: Capsule())
                    // The fill and the track are siblings, not
                    // ancestor/descendant, so the track's own registration
                    // of `neumorphismBackground` never reaches the fill —
                    // see the same fix on `NeumorphismSwitchToggleStyle`'s
                    // knob.
                    .environment(\.neumorphismBackground, Neumorphism.defaultTint)
                    .padding(inset)
                    .animation(.easeOut(duration: 0.2), value: fraction)
            }
        }
        .frame(height: height)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
extension GaugeStyle where Self == NeumorphismLinearCapacityGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled capacity bar.
    public static var neumorphismLinearCapacity: NeumorphismLinearCapacityGaugeStyle {
        NeumorphismLinearCapacityGaugeStyle()
    }
}

// `Gauge`/`GaugeStyleConfiguration` don't exist in the tvOS SDK at all,
// so this preview can't build for that platform's canvas.
#if !os(tvOS)
#Preview("Linear Capacity") {
    VStack(spacing: 30) {
        Gauge(value: 0.4, in: 0...1) {
            Text("Battery")
        } currentValueLabel: {
            Text("40%")
        } minimumValueLabel: {
            Text("0")
        } maximumValueLabel: {
            Text("100")
        }
        .gaugeStyle(.neumorphismLinearCapacity)

        Gauge(value: 0.8, in: 0...1) {
            Text("Storage")
        }
        .gaugeStyle(.neumorphismLinearCapacity)
        .tint(.pink)
    }
    .padding(60)
}
#endif
