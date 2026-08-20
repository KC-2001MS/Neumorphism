import SwiftUI

/// A date picker style that renders as a Neumorphism-styled raised
/// (convex) card behind a compact, editable date field with a popover
/// calendar. The Neumorphism counterpart to `CompactDatePickerStyle`,
/// constructed via ``SwiftUI/DatePickerStyle/neumorphismCompact``.
///
/// ```swift
/// DatePicker("Due date", selection: $dueDate)
///     .datePickerStyle(.neumorphismCompact)
/// ```
///
/// See ``NeumorphismDatePickerStyle`` for why this builds a real
/// `DatePicker` from `configuration.$selection` rather than delegating
/// through a configuration initializer or a `Plain`-style workaround.
@available(iOS 14.0, macOS 10.15.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NeumorphismCompactDatePickerStyle: DatePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
            configuration.label
        }
        .datePickerStyle(.compact)
        .padding()
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 14.0, macOS 10.15.4, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DatePickerStyle where Self == NeumorphismCompactDatePickerStyle {
    /// A date picker style that renders as a Neumorphism-styled raised card.
    public static var neumorphismCompact: NeumorphismCompactDatePickerStyle {
        NeumorphismCompactDatePickerStyle()
    }
}

// `.compact` itself is unavailable on tvOS and watchOS, so this
// preview can't build for either platform's canvas.
#if !os(tvOS) && !os(watchOS)
#Preview("Compact DatePicker") {
    @Previewable @State var date = Date()

    DatePicker("Due date", selection: $date)
        .datePickerStyle(.neumorphismCompact)
        .padding(60)
}
#endif
