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
import UIKit

final class StarMapARModeHelper {
    private enum MotionUnavailableReason: String {
        case deviceMotionUnavailable
        case referenceFrameUnavailable
        case motionStartFailed
    }

    private enum ReferenceFrame: Equatable {
        case magneticNorth
        case trueNorth

        var coreMotionFrame: CMAttitudeReferenceFrame {
            switch self {
            case .magneticNorth:
                return .xMagneticNorthZVertical
            case .trueNorth:
                return .xTrueNorthZVertical
            }
        }

        var appliesGeomagneticDeclination: Bool {
            self == .magneticNorth
        }
    }

    private struct Vector3 {
        let x: Double
        let y: Double
        let z: Double
    }

    private enum CoreMotionErrorCode {
        // CMErrorDeviceRequiresMovement in CoreMotion/CMError.h.
        static let deviceRequiresMovement = 101
        // CMErrorTrueNorthNotAvailable in CoreMotion/CMError.h.
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
    private var activeReferenceFrame: ReferenceFrame?
    private var geomagneticDeclination: Double?

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

    func updateGeomagneticField(location: CLLocation) {
        geomagneticDeclination = GeomagnetismObjCBridge(longitude: location.coordinate.longitude,
                                                        latitude: location.coordinate.latitude,
                                                        altitude: location.altitude,
                                                        date: Date()).declination()
    }

    func toggleArMode() {
        toggleArMode(enable: !isArModeEnabled)
    }

    @discardableResult func toggleArMode(enable: Bool) -> Bool {
        guard isArModeEnabled != enable else {
            return isArModeEnabled
        }
        if enable {
            guard startMotionUpdates() else {
                return false
            }
            isArModeEnabled = true
            onArModeChanged?(true)
            return true
        } else {
            disableArMode()
            return false
        }
    }

    private func startMotionUpdates(using referenceFrame: ReferenceFrame? = nil) -> Bool {
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
        motionManager.startDeviceMotionUpdates(using: referenceFrame.coreMotionFrame, to: queue) { [weak self] motion, error in
            guard let self else {
                return
            }
            if let error {
                self.handleMotionError(error)
                return
            }
            guard self.isRunning,
                  self.isArModeEnabled,
                  let motion,
                  let activeReferenceFrame = self.activeReferenceFrame else {
                return
            }
            let matrix = motion.attitude.rotationMatrix
            let orientation = self.calculateOrientation(rotationMatrix: matrix, referenceFrame: activeReferenceFrame)
            let smoothed = self.smoothOrientation(azimuth: orientation.azimuth, altitude: orientation.altitude)
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning, self.isArModeEnabled else {
                    return
                }
                self.onOrientationChanged?(smoothed.azimuth, smoothed.altitude, orientation.roll)
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
            handleUnavailable(.referenceFrameUnavailable)
        default:
            handleUnavailable(.motionStartFailed)
        }
    }

    private func preferredReferenceFrame() -> ReferenceFrame? {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        if available.contains(.xMagneticNorthZVertical) {
            return .magneticNorth
        }
        if available.contains(.xTrueNorthZVertical) {
            return .trueNorth
        }
        return nil
    }

    private func calculateOrientation(rotationMatrix matrix: CMRotationMatrix,
                                      referenceFrame: ReferenceFrame) -> (azimuth: Double, altitude: Double, roll: Double) {
        let forwardReference = referenceVector(forDeviceVector: Vector3(x: 0, y: 0, z: -1), rotationMatrix: matrix)
        let east = -forwardReference.y
        let north = forwardReference.x
        let up = max(-1.0, min(1.0, forwardReference.z))

        var azimuth = AstroUtils.normalizedDegrees(atan2(east, north) * 180.0 / .pi)
        if referenceFrame.appliesGeomagneticDeclination, let declination = geomagneticDeclination {
            azimuth = AstroUtils.normalizedDegrees(azimuth + declination)
        }
        let altitude = asin(up) * 180.0 / .pi
        let roll = calculateRoll(rotationMatrix: matrix)
        return (azimuth, altitude, roll)
    }

    private func referenceVector(forDeviceVector vector: Vector3, rotationMatrix matrix: CMRotationMatrix) -> Vector3 {
        Vector3(x: matrix.m11 * vector.x + matrix.m21 * vector.y + matrix.m31 * vector.z,
                y: matrix.m12 * vector.x + matrix.m22 * vector.y + matrix.m32 * vector.z,
                z: matrix.m13 * vector.x + matrix.m23 * vector.y + matrix.m33 * vector.z)
    }

    private func deviceVector(forReferenceVector vector: Vector3, rotationMatrix matrix: CMRotationMatrix) -> Vector3 {
        Vector3(x: matrix.m11 * vector.x + matrix.m12 * vector.y + matrix.m13 * vector.z,
                y: matrix.m21 * vector.x + matrix.m22 * vector.y + matrix.m23 * vector.z,
                z: matrix.m31 * vector.x + matrix.m32 * vector.y + matrix.m33 * vector.z)
    }

    private func calculateRoll(rotationMatrix matrix: CMRotationMatrix) -> Double {
        let zenithDevice = deviceVector(forReferenceVector: Vector3(x: 0, y: 0, z: 1), rotationMatrix: matrix)
        let screenZenith = screenVector(forDeviceVector: zenithDevice)
        return atan2(screenZenith.x, screenZenith.y) * 180.0 / .pi
    }

    private func screenVector(forDeviceVector vector: Vector3) -> (x: Double, y: Double) {
        switch ScreenOrientationHelper.sharedInstance.getCurrentInterfaceOrientation() {
        case .landscapeLeft:
            return (x: -vector.y, y: vector.x)
        case .portraitUpsideDown:
            return (x: -vector.x, y: -vector.y)
        case .landscapeRight:
            return (x: vector.y, y: -vector.x)
        default:
            return (x: vector.x, y: vector.y)
        }
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
