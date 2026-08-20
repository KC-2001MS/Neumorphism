import SwiftUI

/// A control group style that renders as a Neumorphism-styled card: a
/// raised (convex) panel holding the group's controls. The Neumorphism
/// counterpart to `AutomaticControlGroupStyle`, constructed via
/// ``SwiftUI/ControlGroupStyle/neumorphism``.
///
/// ```swift
/// ControlGroup {
///     Button("Cut") { }
///     Button("Copy") { }
///     Button("Paste") { }
/// }
/// .controlGroupStyle(.neumorphism)
/// ```
///
/// `ControlGroupStyleConfiguration` exposes no way to reach the group's
/// individual controls directly, and although `ControlGroup` does have
/// an `init(_ configuration:)` overload (unlike `TextEditor`), simply
/// delegating straight through to it — the way ``NeumorphismFormStyle``
/// and ``NeumorphismGroupBoxStyle`` delegate to `Form`/`GroupBox` — was
/// the wrong move here: unlike a form or group box, a control group's
/// entire visual identity as a *fused segmented control* is exactly the
/// system look this package exists to replace, so drawing the real
/// `ControlGroup` and merely framing it just leaves the untouched
/// system segmented control sitting on top of a Neumorphism card,
/// rather than actually rendering it in this style. Applying
/// `.buttonStyle(_:)` to `configuration.content` instead lets every
/// `Button` inside re-render as its own Neumorphism control.
///
/// Giving every button the same plain `Rectangle` bump and clipping the
/// whole row to a capsule afterward was tried first, and rejected:
/// `neumorphismEffect`'s shadow is computed for whatever shape it's
/// given *before* any later clip ever runs, so the crop sliced straight
/// through an already-rendered rectangular shadow instead of bounding a
/// shape that was ever actually shaded as rounded. The fix isn't to
/// drop the per-button rounding, it's to compute the *correct* shape
/// for each button — rounded on whichever of its own sides actually
/// sits at the row's outer edge, square on the sides that just abut a
/// neighbor — before ever asking `neumorphismEffect` to shade it, so
/// the shadow itself is correct from the start with nothing left to
/// crop away. `configuration.content` never reveals which button is
/// first or last, but each button's own position *relative to the
/// row's bounds* is real, measurable geometry: ``NeumorphismSegmentRow``
/// reads the row's overall size, ``NeumorphismSegmentButtonStyle`` reads
/// each button's own frame within that same coordinate space, and
/// whichever edges come within half a point of the row's own edges are
/// the ones that get rounded.
@available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
@available(watchOS, unavailable)
public struct NeumorphismControlGroupStyle: ControlGroupStyle {
    public func makeBody(configuration: Configuration) -> some View {
        NeumorphismSegmentRow {
            configuration.content
        }
    }
}

/// The measuring/layout half of ``NeumorphismControlGroupStyle``: reads
/// its own size once laid out, and hands it to every button inside via
/// ``NeumorphismSegmentButtonStyle`` so each one can compare its own
/// frame against it.
private struct NeumorphismSegmentRow<Content: View>: View {
    var content: Content

    @State private var rowSize: CGSize = .zero

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private static var coordinateSpace: NamedCoordinateSpace { .named("NeumorphismControlGroupRow") }

    var body: some View {
        HStack(spacing: 2) {
            content
        }
        .buttonStyle(NeumorphismSegmentButtonStyle(rowSize: rowSize, coordinateSpace: Self.coordinateSpace))
        .coordinateSpace(Self.coordinateSpace)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { rowSize = proxy.size }
                    .onChange(of: proxy.size) { _, newSize in rowSize = newSize }
            }
        )
    }
}

/// The per-button half of ``NeumorphismControlGroupStyle``: measures
/// its own frame in the row's coordinate space and rounds only the
/// corners on whichever sides that frame actually touches the row's
/// own edges, so the leading button rounds only its leading corners,
/// the trailing button only its trailing corners, and anything in
/// between — abutting a neighbor on both sides — stays square.
private struct NeumorphismSegmentButtonStyle: ButtonStyle {
    var rowSize: CGSize
    var coordinateSpace: NamedCoordinateSpace

    func makeBody(configuration: Configuration) -> some View {
        NeumorphismSegmentButtonLabel(
            label: configuration.label,
            isPressed: configuration.isPressed,
            rowSize: rowSize,
            coordinateSpace: coordinateSpace
        )
    }
}

private struct NeumorphismSegmentButtonLabel<Label: View>: View {
    var label: Label
    var isPressed: Bool
    var rowSize: CGSize
    var coordinateSpace: NamedCoordinateSpace

    @State private var frameInRow: CGRect = .zero

    // Half the row's height, the same "fully rounded on whichever end
    // is open" proportions a capsule uses.
    private var cornerRadius: CGFloat { rowSize.height / 2 }

    var body: some View {
        // A fraction of a point of slack: layout can settle a button's
        // edge at, e.g., 0.999...px from the row's own edge rather than
        // exactly 0, and without slack that reads as "not actually at
        // the edge" and never rounds.
        let tolerance: CGFloat = 0.5
        let isLeading = frameInRow.minX <= tolerance
        let isTrailing = frameInRow.maxX >= rowSize.width - tolerance
        let shape = NeumorphismSegmentShape(cornerRadius: cornerRadius, roundsLeading: isLeading, roundsTrailing: isTrailing)

        label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .neumorphismEffect(isPressed ? .pressed : .regular, in: shape)
            // Without this, the system focus ring defaults to each
            // segment's bounding rectangle regardless of `shape` — a
            // square ring around "Cut"'s rounded-leading corners or
            // "Paste"'s rounded-trailing ones, the same fix
            // `NeumorphismButtonStyle` needs and for the same reason
            // (`.focusEffect` is macOS-only, hence the shared modifier).
            .modifier(NeumorphismFocusEffectShape(shape: shape))
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { frameInRow = proxy.frame(in: coordinateSpace) }
                        .onChange(of: proxy.size) { _, _ in frameInRow = proxy.frame(in: coordinateSpace) }
                }
            )
    }
}

/// A rectangle rounded on only its leading and/or trailing sides —
/// both corners on a rounded side share `cornerRadius`, the sides left
/// unrounded stay perfectly square — the shape
/// ``NeumorphismSegmentButtonLabel`` computes per button from real,
/// measured geometry rather than any positional index.
private struct NeumorphismSegmentShape: Shape {
    var cornerRadius: CGFloat
    var roundsLeading: Bool
    var roundsTrailing: Bool

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: roundsLeading ? cornerRadius : 0,
            bottomLeadingRadius: roundsLeading ? cornerRadius : 0,
            bottomTrailingRadius: roundsTrailing ? cornerRadius : 0,
            topTrailingRadius: roundsTrailing ? cornerRadius : 0,
            style: .continuous
        ).path(in: rect)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension ControlGroupStyle where Self == NeumorphismControlGroupStyle {
    /// A control group style that renders as a Neumorphism-styled card.
    public static var neumorphism: NeumorphismControlGroupStyle {
        NeumorphismControlGroupStyle()
    }
}

// `ControlGroup` itself (not just this style) is unavailable on
// watchOS, so this preview can't build for that platform's canvas.
#if !os(watchOS)
#Preview("ControlGroup") {
    VStack(spacing: 24) {
        ControlGroup {
            Button("Cut") {}
            Button("Copy") {}
            Button("Paste") {}
        }
        .controlGroupStyle(.neumorphism)

        ControlGroup("Alignment") {
            Button("Left") {}
            Button("Center") {}
            Button("Right") {}
        }
        .controlGroupStyle(.neumorphism)
    }
    .padding(60)
}
#endif
