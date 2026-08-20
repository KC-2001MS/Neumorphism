import SwiftUI

/// A date picker style that renders as a Neumorphism-styled raised
/// (convex) card behind an editable date field, with no popover
/// calendar. The Neumorphism counterpart to `FieldDatePickerStyle`,
/// constructed via ``SwiftUI/DatePickerStyle/neumorphismField``.
///
/// ```swift
/// DatePicker("Due date", selection: $dueDate)
///     .datePickerStyle(.neumorphismField)
/// ```
///
/// `FieldDatePickerStyle` itself is macOS-only, the same reason
/// ``NeumorphismCheckboxToggleStyle`` mirrors `CheckboxToggleStyle`
/// being macOS-only. See ``NeumorphismDatePickerStyle`` for why this
/// builds a real `DatePicker` from `configuration.$selection` rather
/// than delegating through a configuration initializer or a
/// `Plain`-style workaround.
@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public struct NeumorphismFieldDatePickerStyle: DatePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
            configuration.label
        }
        .datePickerStyle(.field)
        .padding()
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension DatePickerStyle where Self == NeumorphismFieldDatePickerStyle {
    /// A date picker style that renders as a Neumorphism-styled raised card.
    public static var neumorphismField: NeumorphismFieldDatePickerStyle {
        NeumorphismFieldDatePickerStyle()
    }
}

// `.neumorphismField` is macOS-only, so this preview can't build for
// any other platform's canvas.
#if os(macOS)
#Preview("Field DatePicker") {
    @Previewable @State var date = Date()

    DatePicker("Due date", selection: $date)
        .datePickerStyle(.neumorphismField)
        .padding(60)
}
#endif
