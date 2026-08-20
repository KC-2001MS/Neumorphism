import SwiftUI

/// A date picker style that renders as a Neumorphism-styled raised
/// (convex) card behind an editable date field with an adjoining
/// stepper. The Neumorphism counterpart to `StepperFieldDatePickerStyle`,
/// constructed via ``SwiftUI/DatePickerStyle/neumorphismStepperField``.
///
/// ```swift
/// DatePicker("Due date", selection: $dueDate)
///     .datePickerStyle(.neumorphismStepperField)
/// ```
///
/// `StepperFieldDatePickerStyle` itself is macOS-only, the same reason
/// ``NeumorphismFieldDatePickerStyle`` mirrors `FieldDatePickerStyle`
/// being macOS-only. See ``NeumorphismDatePickerStyle`` for why this
/// builds a real `DatePicker` from `configuration.$selection` rather
/// than delegating through a configuration initializer or a
/// `Plain`-style workaround.
@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public struct NeumorphismStepperFieldDatePickerStyle: DatePickerStyle {
    public func makeBody(configuration: Configuration) -> some View {
        DatePicker(selection: configuration.$selection, displayedComponents: configuration.displayedComponents) {
            configuration.label
        }
        .datePickerStyle(.stepperField)
        .padding()
        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension DatePickerStyle where Self == NeumorphismStepperFieldDatePickerStyle {
    /// A date picker style that renders as a Neumorphism-styled raised card.
    public static var neumorphismStepperField: NeumorphismStepperFieldDatePickerStyle {
        NeumorphismStepperFieldDatePickerStyle()
    }
}

// `.neumorphismStepperField` is macOS-only, so this preview can't
// build for any other platform's canvas.
#if os(macOS)
#Preview("Stepper Field DatePicker") {
    @Previewable @State var date = Date()

    DatePicker("Due date", selection: $date)
        .datePickerStyle(.neumorphismStepperField)
        .padding(60)
}
#endif
