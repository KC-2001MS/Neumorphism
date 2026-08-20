import SwiftUI

/// The default Neumorphism toggle style: basically just `Toggle` itself,
/// deferring to whichever concrete style is platform-appropriate — the
/// same way a plain, unstyled `Toggle` already renders as a checkbox on
/// macOS and a switch elsewhere. This exists only so `.toggleStyle(.neumorphism)`
/// reads the same way `.buttonStyle(.neumorphism)` does; it has no
/// rendering of its own.
///
/// ```swift
/// Toggle("Wi-Fi", isOn: $isWiFiOn)
///     .toggleStyle(.neumorphism)
/// ```
///
/// Use ``NeumorphismSwitchToggleStyle`` or ``NeumorphismCheckboxToggleStyle``
/// directly to opt into one specific appearance regardless of platform.
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public struct NeumorphismDefaultToggleStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        #if os(macOS)
        Toggle(configuration)
            .toggleStyle(.neumorphismCheckbox)
        #else
        // `NeumorphismSwitchToggleStyle` mirrors `SwitchToggleStyle`'s
        // own tvOS 18 floor — below that (down to this style's own
        // tvOS 13 floor), there's no neumorphism-styled tvOS appearance
        // to fall back to, so this leaves the toggle unstyled there
        // rather than referencing a style that isn't available yet.
        if #available(tvOS 18.0, *) {
            Toggle(configuration)
                .toggleStyle(.neumorphismSwitch)
        } else {
            Toggle(configuration)
        }
        #endif
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension ToggleStyle where Self == NeumorphismDefaultToggleStyle {
    /// The default Neumorphism toggle style, matching whatever a plain
    /// `Toggle` would use on the current platform.
    public static var neumorphism: NeumorphismDefaultToggleStyle {
        NeumorphismDefaultToggleStyle()
    }
}
