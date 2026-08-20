import SwiftUI

/// A form style that renders as a Neumorphism-styled raised (convex)
/// card behind the form's rows. The Neumorphism counterpart to
/// `AutomaticFormStyle`, constructed via ``SwiftUI/FormStyle/neumorphism``.
///
/// ```swift
/// Form {
///     TextField("Name", text: $name)
///     Toggle("Notifications", isOn: $notificationsOn)
/// }
/// .formStyle(.neumorphism)
/// ```
///
/// `FormStyleConfiguration.content` is a single opaque `View`, the same
/// limitation ``NeumorphismControlGroupStyle`` ran into with its own
/// buttons — `.listRowBackground(_:)`/`.listRowSeparator(_:)` only ever
/// affect the exact view they're attached to, read by an *ancestor*
/// `List`, so applied to the outside of an already-assembled `Form`
/// they land on the form as a whole and do nothing, unlike
/// `.buttonStyle(_:)`'s environment-wide reach. `ForEach(sections:content:)`
/// (new in iOS 18/macOS 15) is what actually solves this: it walks the
/// real `Section`s inside any `View`, `configuration.content` included,
/// handing back each one's own header/content/footer — so each section
/// gets its own raised card, genuinely wrapping the thing `Form` is
/// actually built out of, the same way ``NeumorphismGroupBoxStyle`` and
/// ``NeumorphismControlGroupStyle`` build on the real `GroupBox`/
/// `ControlGroup`. Below that OS floor, `ForEach(sections:)` doesn't
/// exist yet, so this falls back to a real `Form(configuration)` in a
/// single raised card — the same `if #available` fallback shape
/// ``NeumorphismDefaultToggleStyle`` uses for `.neumorphismSwitch`'s own
/// tvOS 18 floor.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
public struct NeumorphismFormStyle: FormStyle {
    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            NeumorphismSectionedForm(content: configuration.content)
        } else {
            Form(configuration)
                .modifier(NeumorphismHiddenScrollBackground())
                .padding(.vertical, 8)
                .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

/// Renders each `Section` inside `content` as its own raised
/// Neumorphism card, stacked with visible margins between them — the
/// same "one card per real structural unit" idea
/// ``NeumorphismControlGroupStyle`` applies per button, just discovered
/// through `ForEach(sections:content:)` instead of measured geometry,
/// since a form's sections (unlike a control group's buttons) really
/// are enumerable. Only `section.content` sits inside the raised card
/// itself — `header`/`footer` sit outside it (above and below), the
/// same way a real grouped list's header/footer are their own plain
/// text floating around the card, never part of the card's own surface.
/// Both are inset by `cornerRadius`, not flush with the card's leading
/// edge: flush alignment lines header/footer text up with the *corner*
/// of the rounded rectangle beneath, where the card's own edge has
/// already curved inward — inset by exactly the radius instead aligns
/// them with where that edge is still straight, the same reasoning any
/// rounded card's caption uses.
@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
private struct NeumorphismSectionedForm<Content: View>: View {
    var content: Content

    private let cornerRadius: CGFloat = 16

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(sections: content) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack { section.header }
                            .font(.headline)
                            .padding(.horizontal, cornerRadius)

                        VStack(alignment: .leading, spacing: 8) {
                            section.content
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .neumorphismEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                        HStack { section.footer }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, cornerRadius)
                    }
                }
            }
            .padding()
        }
    }
}

/// Applies `.scrollContentBackground(.hidden)` where that modifier
/// exists (everywhere but tvOS) and does nothing there, so
/// ``NeumorphismFormStyle``'s pre-iOS-18 fallback doesn't need its own
/// `#if os(tvOS)` branch.
private struct NeumorphismHiddenScrollBackground: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
        #else
        content.scrollContentBackground(.hidden)
        #endif
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension FormStyle where Self == NeumorphismFormStyle {
    /// A form style that renders as a Neumorphism-styled raised card.
    public static var neumorphism: NeumorphismFormStyle {
        NeumorphismFormStyle()
    }
}

#Preview("Form") {
    @Previewable @State var name = "Jane"
    @Previewable @State var isOnline = true
    @Previewable @State var notificationsOn = true

    Form {
        Section("Profile") {
            TextField("Name", text: $name)
            Toggle("Online", isOn: $isOnline)
        }
        Section("Settings") {
            Toggle("Notifications", isOn: $notificationsOn)
        }
    }
    .formStyle(.neumorphism)
    .frame(height: 260)
    .padding(60)
}
