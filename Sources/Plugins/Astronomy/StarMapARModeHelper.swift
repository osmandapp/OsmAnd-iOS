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
    private enum MotionUnavailableReason: String {
        case deviceMotionUnavailable
        case referenceFrameUnavailable
        case motionStartFailed
    }

    private enum CoreMotionErrorCode {
        static let deviceRequiresMovement = 101
        static let trueNorthNotAvailable = 102
    }

    private var motionManager: CMMotionManager?
    private let queue = OperationQueue()
    private let minAlpha = 0.03
    private let maxAlpha = 0.3
    private let jitterThresh = 0.5
    private let moveThresh = 2.0
    private var smoothedAzimuth = 0.0
    private var smoothedAltitude = 45.0
    private var activeReferenceFrame: CMAttitudeReferenceFrame?

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

    private func startMotionUpdates(using referenceFrame: CMAttitudeReferenceFrame? = nil) -> Bool {
        let motionManager = self.motionManager ?? CMMotionManager()
        self.motionManager = motionManager

        guard motionManager.isDeviceMotionAvailable else {
            handleUnavailable(.deviceMotionUnavailable)
            return false
        }
        guard let referenceFrame = referenceFrame ?? preferredReferenceFrame() else {
            handleUnavailable(.referenceFrameUnavailable)
            return false
        }
        guard !isRunning || activeReferenceFrame != referenceFrame else {
            return true
        }

        if isRunning {
            stopMotionUpdates()
        }
        activeReferenceFrame = referenceFrame
        isRunning = true
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.showsDeviceMovementDisplay = true
        motionManager.startDeviceMotionUpdates(using: referenceFrame, to: queue) { [weak self] motion, error in
            guard let self else {
                return
            }
            if let error {
                self.handleMotionError(error)
                return
            }
            guard self.isRunning, self.isArModeEnabled, let attitude = motion?.attitude else {
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
        return true
    }

    private func disableArMode() {
        isArModeEnabled = false
        stopMotionUpdates()
        onArModeChanged?(false)
    }

    private func stopMotionUpdates(waitUntilFinished: Bool = false) {
        isRunning = false
        activeReferenceFrame = nil
        motionManager?.stopDeviceMotionUpdates()
        queue.cancelAllOperations()
        if waitUntilFinished, OperationQueue.current !== queue {
            queue.waitUntilAllOperationsAreFinished()
        }
    }

    private func handleUnavailable(_ reason: MotionUnavailableReason) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.handleUnavailable(reason)
            }
            return
        }
#if DEBUG
        print("StarMapARModeHelper unavailable: \(reason.rawValue)")
#endif
        isArModeEnabled = false
        stopMotionUpdates()
        onUnavailable?()
        onArModeChanged?(false)
    }

    private func handleMotionError(_ error: Error) {
        let nsError = error as NSError
#if DEBUG
        print("StarMapARModeHelper motion error: \(nsError.domain) \(nsError.code)")
#endif
        guard isRunning, isArModeEnabled else {
            return
        }
        guard nsError.domain == CMErrorDomain else {
            handleUnavailable(.motionStartFailed)
            return
        }

        switch nsError.code {
        case CoreMotionErrorCode.deviceRequiresMovement:
            return
        case CoreMotionErrorCode.trueNorthNotAvailable:
            restartMotionUpdatesWithFallback()
        default:
            handleUnavailable(.motionStartFailed)
        }
    }

    private func restartMotionUpdatesWithFallback() {
        let currentFrame = activeReferenceFrame
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isArModeEnabled else {
                return
            }
            guard let fallback = self.preferredReferenceFrame(excluding: currentFrame) else {
                self.handleUnavailable(.referenceFrameUnavailable)
                return
            }
            _ = self.startMotionUpdates(using: fallback)
        }
    }

    private func preferredReferenceFrame(excluding excludedFrame: CMAttitudeReferenceFrame? = nil) -> CMAttitudeReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        let preferredFrames: [CMAttitudeReferenceFrame] = [
            .xTrueNorthZVertical,
            .xMagneticNorthZVertical,
            .xArbitraryCorrectedZVertical,
            .xArbitraryZVertical
        ]
        for frame in preferredFrames {
            if let excludedFrame, frame == excludedFrame {
                continue
            }
            guard available.contains(frame) else {
                continue
            }
            return frame
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
