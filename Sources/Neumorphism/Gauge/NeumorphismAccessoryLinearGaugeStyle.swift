import SwiftUI

/// A gauge style that renders as a Neumorphism-styled bar with a small
/// raised marker at a point along the track indicating the gauge's
/// current value. The Neumorphism counterpart to
/// `AccessoryLinearGaugeStyle`, constructed via
/// ``SwiftUI/GaugeStyle/neumorphismAccessoryLinear``.
///
/// ```swift
/// Gauge(value: speed, in: 0...200) {
///     Text("Speed")
/// }
/// .gaugeStyle(.neumorphismAccessoryLinear)
/// ```
///
/// `AccessoryLinearGaugeStyle` and `LinearGaugeStyle` share the same
/// documented appearance (a bar with a marker) — the system's own
/// distinction between them is about *where* they're allowed to appear
/// (Lock Screen/watch complications vs. anywhere), which doesn't affect
/// how this package draws them, so this shares
/// ``NeumorphismLinearGaugeStyle``'s rendering — but through the free
/// `neumorphismGaugeLinearMarkerBody(configuration:)` function, not by
/// delegating to that style's own `makeBody(configuration:)` directly:
/// `LinearGaugeStyle` is watchOS-only, while `AccessoryLinearGaugeStyle`
/// is also available on iOS and macOS, so depending on the narrower
/// style directly would make this one uncompilable there too.
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
public struct NeumorphismAccessoryLinearGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        neumorphismGaugeLinearMarkerBody(configuration: configuration)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
extension GaugeStyle where Self == NeumorphismAccessoryLinearGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled bar with a marker.
    public static var neumorphismAccessoryLinear: NeumorphismAccessoryLinearGaugeStyle {
        NeumorphismAccessoryLinearGaugeStyle()
    }
}

// `Gauge`/`GaugeStyleConfiguration` don't exist in the tvOS SDK at all,
// so this preview can't build for that platform's canvas.
#if !os(tvOS)
#Preview("Accessory Linear") {
    Gauge(value: 0.4, in: 0...1) {
        Text("Speed")
    } currentValueLabel: {
        Text("40%")
    } minimumValueLabel: {
        Text("0")
    } maximumValueLabel: {
        Text("100")
    }
    .gaugeStyle(.neumorphismAccessoryLinear)
    .padding(60)
}
#endif
