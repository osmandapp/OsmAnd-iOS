//
//  StarMapARModeHelper.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreMotion
import Foundation

final class StarMapARModeHelper {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    var onOrientationChanged: ((_ azimuth: Double, _ altitude: Double, _ roll: Double) -> Void)?
    var onUnavailable: (() -> Void)?
    private(set) var isRunning = false

    func start() {
        guard motionManager.isDeviceMotionAvailable else {
            onUnavailable?()
            return
        }
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
        isRunning = false
        motionManager.stopDeviceMotionUpdates()
    }
}

