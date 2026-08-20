import SwiftUI

/// A toggle style that renders as a Neumorphism-styled checkbox: a small,
/// rounded square with a concave (pressed) dent, filled with a fixed blue
/// and a checkmark once checked — regardless of the ambient `tint(_:)`
/// view modifier, the same way ``NeumorphismSwitchToggleStyle`` always
/// turns a fixed green. Mirrors `CheckboxToggleStyle`, which is
/// macOS-only for the same reason this style is.
///
/// ```swift
/// Toggle("Remember me", isOn: $isRemembered)
///     .toggleStyle(.neumorphismCheckbox)
/// ```
@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
public struct NeumorphismCheckboxToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack {
            NeumorphismCheckboxBox(isOn: configuration.isOn)
            configuration.label
        }
        .contentShape(Rectangle())
        .onTapGesture {
            configuration.isOn.toggle()
        }
    }
}

/// The box of a ``NeumorphismCheckboxToggleStyle`` checkbox, as its own
/// named view for the same reason ``NeumorphismProminentButtonStyle``
/// splits its label out: a stable identity for `isOn` to animate in place.
private struct NeumorphismCheckboxBox: View {
    var isOn: Bool

    private let size: CGFloat = 16

    var body: some View {
        Color.clear
            .frame(width: size, height: size)
            .neumorphismEffect(
                isOn ? Neumorphism.checkedCheckboxBase : Neumorphism.checkboxBase,
                in: RoundedRectangle(cornerRadius: 4, style: .continuous)
            )
            .overlay {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.65, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .animation(.easeOut(duration: 0.15), value: isOn)
    }
}

@available(macOS 10.15, *)
@available(iOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
extension ToggleStyle where Self == NeumorphismCheckboxToggleStyle {
    /// A toggle style that renders as a Neumorphism-styled checkbox.
    public static var neumorphismCheckbox: NeumorphismCheckboxToggleStyle {
        NeumorphismCheckboxToggleStyle()
    }
}

// `.neumorphismCheckbox` is macOS-only, matching `CheckboxToggleStyle`
// itself, so this preview can't build for any other platform's canvas.
#if os(macOS)
#Preview("Checkbox") {
    @Previewable @State var isOn = false
    @Previewable @State var isOnAlt = true

    VStack(alignment: .leading, spacing: 24) {
        Toggle("Remember me", isOn: $isOn)
            .toggleStyle(.neumorphismCheckbox)

        Toggle("Subscribe", isOn: $isOnAlt)
            .toggleStyle(.neumorphismCheckbox)
    }
    .padding(60)
}
#endif
