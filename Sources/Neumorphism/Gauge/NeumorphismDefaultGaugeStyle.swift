import SwiftUI

/// The default Neumorphism gauge style: renders as
/// ``NeumorphismCircularGaugeStyle``, the most broadly recognizable
/// gauge shape regardless of platform. The Neumorphism counterpart to
/// `DefaultGaugeStyle`/``SwiftUI/GaugeStyle/automatic``, constructed via
/// ``SwiftUI/GaugeStyle/neumorphism``. Named bare, without an
/// `Automatic` suffix, unlike every other style in this family
/// (``NeumorphismCircularGaugeStyle``, ``NeumorphismLinearGaugeStyle``,
/// ``NeumorphismLinearCapacityGaugeStyle``) — the same way
/// `.buttonStyle(.neumorphism)` and `.toggleStyle(.neumorphism)` are
/// each their own family's bare, unsuffixed default.
///
/// ```swift
/// Gauge(value: batteryLevel) {
///     Text("Battery")
/// }
/// .gaugeStyle(.neumorphism)
/// ```
///
/// Use ``NeumorphismCircularGaugeStyle``, ``NeumorphismLinearGaugeStyle``,
/// or ``NeumorphismLinearCapacityGaugeStyle`` directly to opt into one
/// specific appearance.
@available(iOS 16.0, macOS 13.0, watchOS 7.0, *)
@available(tvOS, unavailable)
public struct NeumorphismDefaultGaugeStyle: GaugeStyle {
    public func makeBody(configuration: Configuration) -> some View {
        // Unlike `Toggle`/`ProgressView`, `Gauge` has no
        // `init(_ configuration:)` to delegate through, so this would
        // otherwise call `NeumorphismCircularGaugeStyle`'s own
        // `makeBody(configuration:)` directly — but that style is
        // watchOS-only, while this one (mirroring `DefaultGaugeStyle`)
        // is also available on iOS and macOS, so it goes through the
        // shared, unrestricted `neumorphismGaugeRingBody(configuration:)`
        // instead, the same reason
        // `NeumorphismAccessoryCircularGaugeStyle` does.
        neumorphismGaugeRingBody(configuration: configuration)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 7.0, *)
@available(tvOS, unavailable)
extension GaugeStyle where Self == NeumorphismDefaultGaugeStyle {
    /// The default Neumorphism gauge style.
    public static var neumorphism: NeumorphismDefaultGaugeStyle {
        NeumorphismDefaultGaugeStyle()
    }
}
