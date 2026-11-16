//
//  SteppedSlider.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class SteppedSlider: UISlider {
    var accessibilityStep: Float?

    override func accessibilityIncrement() {
        guard let accessibilityStep, accessibilityStep > 0 else {
            super.accessibilityIncrement()
            return
        }
        adjustValue(by: accessibilityStep)
    }

    override func accessibilityDecrement() {
        guard let accessibilityStep, accessibilityStep > 0 else {
            super.accessibilityDecrement()
            return
        }
        adjustValue(by: -accessibilityStep)
    }

    private func adjustValue(by increment: Float) {
        guard isEnabled else { return }
        let step = abs(increment)
        let stepIndex = ((value - minimumValue) / step).rounded() + (increment > 0 ? 1 : -1)
        let newValue = min(maximumValue, max(minimumValue, minimumValue + stepIndex * step))
        guard newValue != value else { return }
        value = newValue
        sendActions(for: .valueChanged)
    }
}
