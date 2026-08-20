import SwiftUI

/// A gauge style that renders as a Neumorphism-styled bar that fills
/// from the leading to the trailing edge as the gauge's current value
/// increases. The Neumorphism counterpart to
/// `AccessoryLinearCapacityGaugeStyle`, constructed via
/// ``SwiftUI/GaugeStyle/neumorphismAccessoryLinearCapacity``.
///
/// ```swift
/// Gauge(value: batteryLevel, in: 0...100) {
///     Text("Battery Level")
/// }
/// .gaugeStyle(.neumorphismAccessoryLinearCapacity)
/// ```
///
/// `AccessoryLinearCapacityGaugeStyle` and `LinearCapacityGaugeStyle`
/// share the same documented appearance (a bar that fills from leading
/// to trailing) — the system's own distinction between them is about
/// *where* they're allowed to appear (Lock Screen/watch complications
/// vs. anywhere), which doesn't affect how this package draws them, so
/// this simply reuses ``NeumorphismLinearCapacityGaugeStyle``'s rendering.
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
public struct NeumorphismAccessoryLinearCapacityGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        NeumorphismLinearCapacityGaugeStyle().makeBody(configuration: configuration)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
extension GaugeStyle where Self == NeumorphismAccessoryLinearCapacityGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled capacity bar.
    public static var neumorphismAccessoryLinearCapacity: NeumorphismAccessoryLinearCapacityGaugeStyle {
        NeumorphismAccessoryLinearCapacityGaugeStyle()
    }
}

// `Gauge`/`GaugeStyleConfiguration` don't exist in the tvOS SDK at all,
// so this preview can't build for that platform's canvas.
#if !os(tvOS)
#Preview("Accessory Linear Capacity") {
    Gauge(value: 0.4, in: 0...1) {
        Text("Battery")
    } currentValueLabel: {
        Text("40%")
    } minimumValueLabel: {
        Text("0")
    } maximumValueLabel: {
        Text("100")
    }
    .gaugeStyle(.neumorphismAccessoryLinearCapacity)
    .padding(60)
}
#endif
