import SwiftUI

/// A gauge style that renders as a Neumorphism-styled open ring with a
/// small raised marker at a point along the ring indicating the gauge's
/// current value. The Neumorphism counterpart to
/// `AccessoryCircularGaugeStyle`, constructed via
/// ``SwiftUI/GaugeStyle/neumorphismAccessoryCircular``.
///
/// ```swift
/// Gauge(value: current, in: 0...170) {
///     Text("BPM")
/// }
/// .gaugeStyle(.neumorphismAccessoryCircular)
/// ```
///
/// `AccessoryCircularGaugeStyle` and `CircularGaugeStyle` share the same
/// documented appearance (an open ring with a marker) — the system's own
/// distinction between them is about *where* they're allowed to appear
/// (Lock Screen/watch complications vs. anywhere), which doesn't affect
/// how this package draws them, so this shares
/// ``NeumorphismCircularGaugeStyle``'s rendering — but through the free
/// `neumorphismGaugeRingBody(configuration:)` function, not by
/// delegating to that style's own `makeBody(configuration:)` directly:
/// `CircularGaugeStyle` is watchOS-only, while `AccessoryCircularGaugeStyle`
/// is also available on iOS and macOS, so depending on the narrower
/// style directly would make this one uncompilable there too.
@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
public struct NeumorphismAccessoryCircularGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        neumorphismGaugeRingBody(configuration: configuration)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, *)
@available(tvOS, unavailable)
extension GaugeStyle where Self == NeumorphismAccessoryCircularGaugeStyle {
    /// A gauge style that renders as a Neumorphism-styled open ring with a marker.
    public static var neumorphismAccessoryCircular: NeumorphismAccessoryCircularGaugeStyle {
        NeumorphismAccessoryCircularGaugeStyle()
    }
}

// `Gauge`/`GaugeStyleConfiguration` don't exist in the tvOS SDK at all,
// so this preview can't build for that platform's canvas.
#if !os(tvOS)
#Preview("Accessory Circular") {
    HStack(spacing: 40) {
        Gauge(value: 0.4, in: 0...1) {
            Text("Speed")
        } currentValueLabel: {
            Text("40%")
        }
        .gaugeStyle(.accessoryCircular)

        Gauge(value: 0.4, in: 0...1) {
            Text("Speed")
        } currentValueLabel: {
            Text("40%")
        }
        .gaugeStyle(.neumorphismAccessoryCircular)
    }
    .padding(60)
}
#endif
