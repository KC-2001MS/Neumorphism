import SwiftUI

/// A date picker style that renders as a Neumorphism-styled raised
/// (convex) card behind a scrollable wheel of date components. The
/// Neumorphism counterpart to `WheelDatePickerStyle`, constructed via
/// ``SwiftUI/DatePickerStyle/neumorphismWheel``.
///
/// ```swift
/// DatePicker("Due date", selection: $dueDate)
///     .datePickerStyle(.neumorphismWheel)
/// ```
///
/// `WheelDatePickerStyle` itself is unavailable on macOS (unlike
/// ``NeumorphismCompactDatePickerStyle``/``NeumorphismGraphicalDatePickerStyle``,
/// which are unavailable on watchOS instead) — this is the one built-in
/// date picker style watchOS actually supports besides `.automatic`
/// itself. See ``NeumorphismDatePickerStyle`` for why this builds a
/// real `DatePicker` from `configuration.$selection` rather than
/// delegating through a configuration initializer or a `Plain`-style
/// workaround.
@available(iOS 13.0, watchOS 10.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
public struct NeumorphismWheelDatePickerStyle: DatePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
            configuration.label
        }
        .datePickerStyle(.wheel)
        .padding()
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 13.0, watchOS 10.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
extension DatePickerStyle where Self == NeumorphismWheelDatePickerStyle {
    /// A date picker style that renders as a Neumorphism-styled raised card.
    public static var neumorphismWheel: NeumorphismWheelDatePickerStyle {
        NeumorphismWheelDatePickerStyle()
    }
}

// `.wheel` itself is unavailable on macOS and tvOS, so this preview
// can't build for either platform's canvas.
#if !os(macOS) && !os(tvOS)
#Preview("Wheel DatePicker") {
    @Previewable @State var date = Date()

    DatePicker("Due date", selection: $date)
        .datePickerStyle(.neumorphismWheel)
        .padding(60)
}
#endif
