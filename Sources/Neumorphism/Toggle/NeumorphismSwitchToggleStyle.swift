import SwiftUI

/// A toggle style that renders as a Neumorphism-styled switch: a
/// pill-shaped track with a concave (pressed) dent that a pill-shaped,
/// convex (raised) knob slides across.
///
/// ```swift
/// Toggle("Wi-Fi", isOn: $isWiFiOn)
///     .toggleStyle(.neumorphismSwitch)
/// ```
///
/// The track's dent is a fixed green when on and a fixed gray when off,
/// regardless of the ambient `tint(_:)` view modifier or Light/Dark
/// Mode — the same way the system's own switch always turns green (or
/// whatever tint it's given) rather than following an arbitrary surface
/// color, and stays a visible gray rather than fading into a dark page
/// when off.
///
/// Mirrors `SwitchToggleStyle`'s own platform floor — notably tvOS 18,
/// much newer than this package's tvOS 17 minimum — so
/// ``NeumorphismDefaultToggleStyle`` guards its own use of this with
/// `if #available` rather than assuming it whenever `#if os(macOS)` is false.
@available(iOS 13.0, macOS 10.15, tvOS 18.0, watchOS 6.0, *)
public struct NeumorphismSwitchToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            NeumorphismSwitchToggleTrack(isOn: configuration.isOn)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

/// The track/knob dimensions of a ``NeumorphismSwitchToggleStyle`` switch.
/// The system switch's own proportions changed in OS 27, so this library
/// keeps both and picks between them at runtime rather than assuming
/// everyone has updated — call sites just render whatever ``automatic``
/// resolves to.
private struct SwitchMetrics {
    var width: CGFloat
    var height: CGFloat
    var inset: CGFloat
    var knobWidth: CGFloat

    /// Measured from the system switch (iPadOS 27, Settings > Wi-Fi): a
    /// 125×54 track holding a 70×45 knob, inset by ~4.5 on the top,
    /// bottom, and whichever side it's resting against — a wider, flatter
    /// pill than the classic circular knob, not just a scaled-up circle.
    static let current = SwitchMetrics(width: 70, height: 30, inset: 2.5, knobWidth: 39)

    /// The classic switch geometry (pre-OS 27): a circular knob
    /// (`knobWidth` equal to the inset-adjusted height) centered evenly
    /// on all sides.
    static let classic = SwitchMetrics(width: 50, height: 30, inset: 2, knobWidth: 26)

    static var automatic: SwitchMetrics {
        if #available(iOS 27, macOS 27, macCatalyst 27, tvOS 27, visionOS 27, *) {
            .current
        } else {
            .classic
        }
    }
}

/// The track and knob of a ``NeumorphismSwitchToggleStyle`` switch, as its
/// own named view for the same reason ``NeumorphismProminentButtonStyle``
/// splits its label out: a stable identity for `isOn` to animate in place.
private struct NeumorphismSwitchToggleTrack: View {
    var isOn: Bool

    var body: some View {
        let metrics = SwitchMetrics.automatic
        let knobHeight = metrics.height - metrics.inset * 2
        let trackColor: Color = isOn ? .green : .gray
        ZStack(alignment: .leading) {
            Color.clear
                .frame(width: metrics.width, height: metrics.height)
                .neumorphismEffect(
                    Neumorphism.switchTrackBase.tint(trackColor),
                    in: Capsule()
                )
            Color.clear
                .frame(width: metrics.knobWidth, height: knobHeight)
                .neumorphismEffect(Neumorphism.switchKnobBase, in: Capsule())
                .padding(metrics.inset)
                .offset(x: isOn ? metrics.width - 2 * metrics.inset - metrics.knobWidth : 0)
                // The knob and the track are siblings in this `ZStack`, not
                // ancestor/descendant, so the track's own registration of
                // `neumorphismBackground` (from inside its `neumorphismEffect`)
                // never reaches the knob — it still sees the page behind
                // this whole control. Registering the track's actual dent
                // color here directly is what makes the knob's outer glow
                // blend with what it's really sitting on.
                .environment(\.neumorphismBackground, trackColor)
        }
        .animation(.easeOut(duration: 0.15), value: isOn)
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 18.0, watchOS 6.0, *)
extension ToggleStyle where Self == NeumorphismSwitchToggleStyle {
    /// A toggle style that renders as a Neumorphism-styled switch.
    public static var neumorphismSwitch: NeumorphismSwitchToggleStyle {
        NeumorphismSwitchToggleStyle()
    }
}

// `.neumorphismSwitch` needs tvOS 18 — newer than this package's own
// tvOS 17 floor — so this preview can't build below that on tvOS.
@available(tvOS 18.0, *)
#Preview("Toggle") {
    @Previewable @State var isOn = false
    @Previewable @State var isOnAlt = true

    VStack(spacing: 24) {
        Toggle("Wi-Fi", isOn: $isOn)
            .toggleStyle(.neumorphismSwitch)

        Toggle("Bluetooth", isOn: $isOnAlt)
            .toggleStyle(.neumorphismSwitch)
    }
    .padding(60)
}
