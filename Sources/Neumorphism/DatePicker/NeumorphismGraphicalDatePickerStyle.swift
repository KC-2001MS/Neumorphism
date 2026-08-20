import SwiftUI

/// A date picker style that renders as a Neumorphism-styled raised
/// (convex) card behind an interactive calendar. The Neumorphism
/// counterpart to `GraphicalDatePickerStyle`, constructed via
/// ``SwiftUI/DatePickerStyle/neumorphismGraphical``.
///
/// ```swift
/// DatePicker("Due date", selection: $dueDate)
///     .datePickerStyle(.neumorphismGraphical)
/// ```
///
/// See ``NeumorphismDatePickerStyle`` for why this builds a real
/// `DatePicker` from `configuration.$selection` rather than delegating
/// through a configuration initializer or a `Plain`-style workaround.
@available(iOS 14.0, macOS 10.15, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct NeumorphismGraphicalDatePickerStyle: DatePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
            configuration.label
        }
        .datePickerStyle(.graphical)
        .padding()
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 14.0, macOS 10.15, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DatePickerStyle where Self == NeumorphismGraphicalDatePickerStyle {
    /// A date picker style that renders as a Neumorphism-styled raised card.
    public static var neumorphismGraphical: NeumorphismGraphicalDatePickerStyle {
        NeumorphismGraphicalDatePickerStyle()
    }
}

// `.graphical` itself is unavailable on tvOS and watchOS, so this
// preview can't build for either platform's canvas.
#if !os(tvOS) && !os(watchOS)
#Preview("Graphical DatePicker") {
    @Previewable @State var date = Date()

    DatePicker("Due date", selection: $date)
        .datePickerStyle(.neumorphismGraphical)
        .padding(60)
}
#endif
