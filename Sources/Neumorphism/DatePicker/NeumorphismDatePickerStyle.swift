import SwiftUI

/// A date picker style that renders as a Neumorphism-styled raised
/// (convex) card behind the platform's own automatic date picker
/// appearance. The Neumorphism counterpart to `DefaultDatePickerStyle`,
/// constructed via ``SwiftUI/DatePickerStyle/neumorphism``.
///
/// ```swift
/// DatePicker("Due date", selection: $dueDate)
///     .datePickerStyle(.neumorphism)
/// ```
///
/// `DatePickerStyleConfiguration` exposes no `DatePicker.init(_
/// configuration:)` to delegate through — unlike `Toggle`, `ProgressView`,
/// `GroupBox`, `ControlGroup`, and `Form` — but unlike `TextEditor`, it
/// *does* expose the picker's own `$selection` binding directly, so
/// there's no need for a `PlainDatePickerStyle`-style workaround either:
/// this builds a real `DatePicker` from that binding.
///
/// Deliberately doesn't force any particular `.datePickerStyle(_:)` of
/// its own (unlike ``NeumorphismCompactDatePickerStyle`` and its
/// siblings): `DefaultDatePickerStyle` is available everywhere a
/// `DatePicker` is (down to watchOS, where none of `.compact`,
/// `.graphical`, `.field`, or `.stepperField` exist at all), so forcing
/// any one of those underneath would narrow this style's own real
/// range. Leaving the picker unstyled instead just inherits whatever
/// that platform's own true default already is — `.wheel`-like on
/// watchOS, `.compact`-like on iOS/macOS — the same thing "automatic"
/// means everywhere else in this package.
@available(iOS 13.0, macOS 10.15, watchOS 10.0, *)
@available(tvOS, unavailable)
public struct NeumorphismDatePickerStyle: DatePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
            configuration.label
        }
        .padding()
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 10.0, *)
@available(tvOS, unavailable)
extension DatePickerStyle where Self == NeumorphismDatePickerStyle {
    /// A date picker style that renders as a Neumorphism-styled raised card.
    public static var neumorphism: NeumorphismDatePickerStyle {
        NeumorphismDatePickerStyle()
    }
}

// `.neumorphism` itself is unavailable on tvOS, so this preview can't
// build for that platform's canvas.
#if !os(tvOS)
#Preview("DatePicker") {
    @Previewable @State var date = Date()

    DatePicker("Due date", selection: $date)
        .datePickerStyle(.neumorphism)
        .padding(60)
}
#endif
