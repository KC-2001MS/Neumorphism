import SwiftUI

/// A progress view style that renders as a Neumorphism-styled bar: a
/// pill-shaped, concave (pressed) track that a pill-shaped, convex
/// (raised) fill grows across as progress advances. The Neumorphism
/// counterpart to `LinearProgressViewStyle`, constructed via
/// ``SwiftUI/ProgressViewStyle/linear``.
///
/// ```swift
/// ProgressView(value: progress)
///     .progressViewStyle(.neumorphismLinear)
/// ```
///
/// The fill follows the ambient `tint(_:)` view modifier (or the app's
/// accent color), the same way a system progress bar's fill does. When
/// the progress is indeterminate (no `value` was given), the same
/// percentage-driven fill is reused, just fed a fraction that keeps
/// growing from `0` to `1` and resetting, instead of a real value.
@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
public struct NeumorphismLinearProgressViewStyle: ProgressViewStyle {
    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            configuration.label
            NeumorphismLinearProgressTrack(fractionCompleted: configuration.fractionCompleted)
            configuration.currentValueLabel
        }
    }
}

/// The track and fill of a ``NeumorphismLinearProgressViewStyle`` bar, as
/// its own named view for the same reason ``NeumorphismProminentButtonStyle``
/// splits its label out: a stable identity for the fill to animate in
/// place as `fractionCompleted` changes.
private struct NeumorphismLinearProgressTrack: View {
    var fractionCompleted: Double?

    private let height: CGFloat = 16
    // A gap between the fill and the track's own edges, the same way
    // `NeumorphismSwitchToggleStyle`'s knob floats inset within its
    // track rather than sitting flush against it.
    private let inset: CGFloat = 3

    var body: some View {
        GeometryReader { proxy in
            let innerWidth = proxy.size.width - inset * 2
            let innerHeight = height - inset * 2
            ZStack(alignment: .leading) {
                Color.clear
                    .neumorphismEffect(Neumorphism.progressTrackBase, in: Capsule())
                Group {
                    if let fractionCompleted {
                        NeumorphismLinearFill(width: innerWidth, height: innerHeight, fraction: fractionCompleted)
                            .animation(.easeOut(duration: 0.2), value: fractionCompleted)
                    } else {
                        NeumorphismLinearIndeterminateFill(width: innerWidth, height: innerHeight)
                    }
                }
                .padding(inset)
            }
        }
        .frame(height: height)
    }
}

/// The fill of a ``NeumorphismLinearProgressViewStyle`` bar, sized to
/// `fraction` (`0`...`1`) of `width`. Both the determinate case
/// (`fractionCompleted`) and the indeterminate case (a fraction that
/// keeps growing and resetting, see ``NeumorphismLinearIndeterminateFill``)
/// go through this same view — a progress bar is fundamentally a fraction
/// rendered as a width, indeterminate or not.
private struct NeumorphismLinearFill: View {
    var width: CGFloat
    var height: CGFloat
    var fraction: Double

    var body: some View {
        let fillWidth = max(height, width * CGFloat(min(1, max(0, fraction))))
        Color.clear
            .frame(width: fillWidth)
            .neumorphismEffect(Neumorphism.progressFillBase, in: Capsule())
            // The fill and the track are siblings in the parent `ZStack`,
            // not ancestor/descendant, so the track's own registration of
            // `neumorphismBackground` (from inside its `neumorphismEffect`)
            // never reaches the fill — see the same fix on
            // `NeumorphismSwitchToggleStyle`'s knob.
            .environment(\.neumorphismBackground, Neumorphism.defaultTint)
    }
}

/// The indeterminate case of ``NeumorphismLinearFill``: no `value` was
/// given to the `ProgressView`, so this drives the same fraction-based
/// fill with a fraction that repeatedly grows from `0` to `1` and resets,
/// rather than a real value.
///
/// Driven by `TimelineView` rather than `withAnimation(...).repeatForever(...)`:
/// an indefinitely-repeating animation transaction was observed to corrupt
/// how *every* dynamic system color (like ``Neumorphism/defaultTint``)
/// resolves for the rest of that render pass, rendering Light Mode
/// surfaces black — including on other, unrelated progress bars sharing
/// the same view hierarchy. Recomputing a plain (unanimated) fraction from
/// the current time on every frame sidesteps that transaction entirely.
private struct NeumorphismLinearIndeterminateFill: View {
    var width: CGFloat
    var height: CGFloat

    private let period: Double = 1.4

    var body: some View {
        TimelineView(.animation) { context in
            let fraction = context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: period) / period
            NeumorphismLinearFill(width: width, height: height, fraction: fraction)
        }
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension ProgressViewStyle where Self == NeumorphismLinearProgressViewStyle {
    /// A progress view style that renders as a Neumorphism-styled linear bar.
    public static var neumorphismLinear: NeumorphismLinearProgressViewStyle {
        NeumorphismLinearProgressViewStyle()
    }
}

#Preview("Progress") {
    VStack(spacing: 24) {
        ProgressView(value: 0.3)
            .progressViewStyle(.neumorphismLinear)

        ProgressView(value: 0.7)
            .progressViewStyle(.neumorphismLinear)
            .tint(.pink)

        ProgressView("Downloading…", value: 0.5)
            .progressViewStyle(.neumorphismLinear)

        ProgressView()
            .progressViewStyle(.neumorphismLinear)
    }
    .padding(60)
}
