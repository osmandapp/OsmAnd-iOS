//
//  StarMapARModeHelper.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreMotion
import CoreLocation
import Foundation

final class StarMapARModeHelper {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    var onOrientationChanged: ((_ azimuth: Double, _ altitude: Double, _ roll: Double) -> Void)?
    var onUnavailable: (() -> Void)?
    var isArModeEnabled = false
    private(set) var isRunning = false

    func onResume() {
        if isArModeEnabled {
            start()
        }
    }

    func onPause() {
        stop()
    }

    func updateGeomagneticField(location: CLLocation) {
    }

    func toggleArMode() {
        toggleArMode(enable: !isArModeEnabled)
    }

    func toggleArMode(enable: Bool) {
        isArModeEnabled = enable
        if enable {
            start()
        } else {
            stop()
        }
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            onUnavailable?()
            return
        }
        isArModeEnabled = true
        isRunning = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: queue) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else {
                return
            }
            let yaw = AstroUtils.normalizedDegrees(attitude.yaw * 180.0 / .pi)
            let pitch = attitude.pitch * 180.0 / .pi
            let roll = attitude.roll * 180.0 / .pi
            let altitude = max(-85, min(90, 90 + pitch))
            DispatchQueue.main.async {
                self.onOrientationChanged?(yaw, altitude, roll)
            }
        }
    }

    func stop() {
        isArModeEnabled = false
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
    }

    private func calculateAdaptiveAlpha(_ delta: Double) -> Double {
        let absDelta = abs(delta)
        if absDelta > 30 {
            return 0.35
        }
        if absDelta > 10 {
            return 0.20
        }
        return 0.08
    }
}
