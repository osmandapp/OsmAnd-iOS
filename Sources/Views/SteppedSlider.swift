//
//  SteppedSlider.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class SteppedSlider: UISlider {
    /// Adjustments move to the next grid value in the requested direction, starting at minimumValue.
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
        let currentStepIndex = (value - minimumValue) / step
        let nearestStepIndex = currentStepIndex.rounded()
        let nearestStepOffset = nearestStepIndex * step
        let nearestStepValue = minimumValue + nearestStepOffset
        // Treat Float rounding noise as an on-grid value so repeated adjustments do not stall.
        let roundingTolerance = max(value.ulp, minimumValue.ulp, nearestStepOffset.ulp)
        let isOnStep = abs(value - nearestStepValue) <= roundingTolerance
        let stepIndex = isOnStep
            ? nearestStepIndex + (increment > 0 ? 1 : -1)
            : currentStepIndex.rounded(increment > 0 ? .up : .down)
        let newValue = min(maximumValue, max(minimumValue, minimumValue + stepIndex * step))
        guard newValue != value else { return }
        value = newValue
        sendActions(for: .valueChanged)
    }
}
