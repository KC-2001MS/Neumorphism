# ``Neumorphism``

Bring the soft-UI ("neumorphic") design language to native SwiftUI controls.

## Overview

``Neumorphism`` plays the same role for this material that
[`Glass`](https://developer.apple.com/documentation/swiftui/glass) plays for
the Liquid Glass material: a small, composable value that you configure and
pass to ``SwiftUI/View/neumorphismEffect(_:in:)`` or to a style's
`.neumorphism...` static member, the same way you'd pass `.regular` or
`.clear` to `glassEffect(_:in:)`.

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .neumorphismEffect(.regular, in: .rect(cornerRadius: 20))
```

On top of that shared material, this package provides a full family of
ready-made styles — one set per SwiftUI style protocol — each modeled
directly against Apple's own equivalent, including matching its real
platform and OS-version availability.

```swift
Button("Continue") { }
    .buttonStyle(.neumorphismProminent)
    .tint(.blue)

Toggle("Wi-Fi", isOn: $isWiFiOn)
    .toggleStyle(.neumorphismSwitch)
```

## Topics

### Core material

- ``Neumorphism``
- ``SwiftUI/View/neumorphismEffect(_:in:)``

### Buttons

- ``NeumorphismButtonStyle``
- ``NeumorphismProminentButtonStyle``

### Toggles

- ``NeumorphismDefaultToggleStyle``
- ``NeumorphismSwitchToggleStyle``
- ``NeumorphismCheckboxToggleStyle``

### Gauges

- ``NeumorphismDefaultGaugeStyle``
- ``NeumorphismCircularGaugeStyle``
- ``NeumorphismLinearGaugeStyle``
- ``NeumorphismLinearCapacityGaugeStyle``
- ``NeumorphismAccessoryCircularGaugeStyle``
- ``NeumorphismAccessoryCircularCapacityGaugeStyle``
- ``NeumorphismAccessoryLinearGaugeStyle``
- ``NeumorphismAccessoryLinearCapacityGaugeStyle``

### Progress views

- ``NeumorphismCircularProgressViewStyle``
- ``NeumorphismLinearProgressViewStyle``

### Containers

- ``NeumorphismGroupBoxStyle``
- ``NeumorphismDisclosureGroupStyle``
- ``NeumorphismControlGroupStyle``
- ``NeumorphismFormStyle``

### Text editing

- ``NeumorphismTextEditorStyle``
- ``NeumorphismRoundedBorderTextEditorStyle``

### Date pickers

- ``NeumorphismDatePickerStyle``
- ``NeumorphismCompactDatePickerStyle``
- ``NeumorphismFieldDatePickerStyle``
- ``NeumorphismGraphicalDatePickerStyle``
- ``NeumorphismStepperFieldDatePickerStyle``
- ``NeumorphismWheelDatePickerStyle``
