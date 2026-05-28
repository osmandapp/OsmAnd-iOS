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
    private var motionManager: CMMotionManager?
    private let queue = OperationQueue()
    private let minAlpha = 0.03
    private let maxAlpha = 0.3
    private let jitterThresh = 0.5
    private let moveThresh = 2.0
    private var smoothedAzimuth = 0.0
    private var smoothedAltitude = 45.0

    var onOrientationChanged: ((_ azimuth: Double, _ altitude: Double, _ roll: Double) -> Void)?
    var onUnavailable: (() -> Void)?
    var onArModeChanged: ((_ enabled: Bool) -> Void)?
    private(set) var isArModeEnabled = false
    private(set) var isRunning = false

    init() {
        queue.maxConcurrentOperationCount = 1
    }

    deinit {
        onOrientationChanged = nil
        onUnavailable = nil
        onArModeChanged = nil
        stopMotionUpdates(waitUntilFinished: true)
    }

    func onResume() {
        if isArModeEnabled {
            _ = startMotionUpdates()
        }
    }

    func onPause() {
        stopMotionUpdates()
    }

    func updateGeomagneticField(location _: CLLocation) {
        // CoreMotion's true-north frame applies platform geomagnetic correction when available.
    }

    func toggleArMode() {
        toggleArMode(enable: !isArModeEnabled)
    }

    func toggleArMode(enable: Bool) {
        guard isArModeEnabled != enable else {
            return
        }

        if enable {
            isArModeEnabled = true
            if startMotionUpdates() {
                onArModeChanged?(true)
            }
        } else {
            disableArMode()
        }
    }

    private func startMotionUpdates() -> Bool {
        let motionManager = self.motionManager ?? CMMotionManager()
        self.motionManager = motionManager

        guard motionManager.isDeviceMotionAvailable, let referenceFrame = preferredReferenceFrame() else {
            handleUnavailable()
            return false
        }
        guard !isRunning else {
            return true
        }

        isRunning = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(using: referenceFrame, to: queue) { [weak self] motion, _ in
            guard let self, self.isRunning, self.isArModeEnabled, let attitude = motion?.attitude else {
                return
            }
            let yaw = AstroUtils.normalizedDegrees(attitude.yaw * 180.0 / .pi)
            let pitch = attitude.pitch * 180.0 / .pi
            let roll = attitude.roll * 180.0 / .pi
            let altitude = max(-85, min(90, 90 + pitch))
            let smoothed = self.smoothOrientation(azimuth: yaw, altitude: altitude)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning, self.isArModeEnabled else {
                    return
                }
                self.onOrientationChanged?(smoothed.azimuth, smoothed.altitude, roll)
            }
        }

        if !motionManager.isDeviceMotionActive {
            handleUnavailable()
            return false
        }
        return true
    }

    private func disableArMode() {
        isArModeEnabled = false
        stopMotionUpdates()
        onArModeChanged?(false)
    }

    private func stopMotionUpdates(waitUntilFinished: Bool = false) {
        isRunning = false
        motionManager?.stopDeviceMotionUpdates()
        queue.cancelAllOperations()
        if waitUntilFinished, OperationQueue.current !== queue {
            queue.waitUntilAllOperationsAreFinished()
        }
    }

    private func handleUnavailable() {
        isArModeEnabled = false
        stopMotionUpdates()
        onUnavailable?()
        onArModeChanged?(false)
    }

    private func preferredReferenceFrame() -> CMAttitudeReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        if available.contains(.xTrueNorthZVertical) {
            return .xTrueNorthZVertical
        }
        if available.contains(.xMagneticNorthZVertical) {
            return .xMagneticNorthZVertical
        }
        return nil
    }

    private func smoothOrientation(azimuth: Double, altitude: Double) -> (azimuth: Double, altitude: Double) {
        let azimuthDelta = AstroUtils.shortestAngleDelta(from: smoothedAzimuth, to: azimuth)
        let alphaAz = calculateAdaptiveAlpha(azimuthDelta)
        smoothedAzimuth = AstroUtils.normalizedDegrees(smoothedAzimuth + azimuthDelta * alphaAz)

        let altitudeDelta = altitude - smoothedAltitude
        let alphaAlt = calculateAdaptiveAlpha(altitudeDelta)
        smoothedAltitude += altitudeDelta * alphaAlt

        return (smoothedAzimuth, smoothedAltitude)
    }

    private func calculateAdaptiveAlpha(_ delta: Double) -> Double {
        let absDelta = abs(delta)
        if absDelta < jitterThresh {
            return minAlpha
        }
        if absDelta > moveThresh {
            return maxAlpha
        }
        return minAlpha + (absDelta - jitterThresh) * (maxAlpha - minAlpha) / (moveThresh - jitterThresh)
    }
}
