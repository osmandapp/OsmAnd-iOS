//
//  InclinometerSensor.swift
//  OsmAnd Maps
//
//  Created by Eugene Zmeuk on 02.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import CoreMotion
import UIKit
import simd

protocol InclinometerListener: AnyObject {
    func onInclinationChanged(pitch: Float, roll: Float)
    // false when the listener no longer needs updates; the sensor is released once every listener is inactive
    var isInclinometerActive: Bool { get }
}

/// Measures the vehicle pitch (positive = front raised) and roll (positive = right side lowered)
/// from the device gravity vector. `calibrate()` stores the current device attitude as the
/// level position, so the device can be mounted at any angle; without calibration the device is
/// assumed to lie flat with the top of the screen forward. The motion updates run only while at
/// least one `InclinometerListener` is active. Must be used from the main thread.
@objc(OAInclinometerSensor)
@objcMembers
final class InclinometerSensor: NSObject {

    static let shared = InclinometerSensor()

    private static let calibrationPrefId = "inclinometer_calibration"
    private static let updateInterval: TimeInterval = 0.1
    private static let listenersCheckInterval: TimeInterval = 1
    private static let accelerometerFilterAlpha: Float = 0.2
    private static let maxAngleDegrees: Float = 85
    private static let minForwardProjection: Float = 0.05

    private final class WeakListener {
        weak var listener: InclinometerListener?
        init(_ listener: InclinometerListener) {
            self.listener = listener
        }
    }

    private let calibrationPref: OACommonString
    private let motionManager = CMMotionManager()
    private var listeners = [WeakListener]()
    private var listenersCheckTimer: Timer?

    // Device "up" direction (opposite to gravity) in device coordinates
    private var up = SIMD3<Float>(0, 0, 1)
    private(set) var hasValue = false
    private var running = false
    private var usingAccelerometer = false

    private(set) var pitch: Float = 0
    private(set) var roll: Float = 0

    // Level position in device coordinates, nil until calibrated
    private var calibratedUp: SIMD3<Float>?
    private var calibratedForward: SIMD3<Float>?

    private override init() {
        calibrationPref = OAAppSettings.sharedManager()
            .registerStringPreference(Self.calibrationPrefId, defValue: "")
            .makeGlobal()
        super.init()
        parseCalibration(calibrationPref.get())
    }

    var isSensorAvailable: Bool {
        motionManager.isDeviceMotionAvailable || motionManager.isAccelerometerAvailable
    }

    var isCalibrated: Bool {
        calibratedUp != nil && calibratedForward != nil
    }

    /// The device tilt stored as the level position, (pitch, roll) in degrees
    /// relative to the device lying flat, or nil when not calibrated
    var calibrationOffset: (pitch: Float, roll: Float)? {
        guard let calibratedUp else {
            return nil
        }
        let forward = screenTopAxis()
        let right = simd_cross(forward, SIMD3<Float>(0, 0, 1))
        let offsetPitch = Self.degrees(asin(Self.clampUnit(simd_dot(calibratedUp, forward))))
        let offsetRoll = -Self.degrees(asin(Self.clampUnit(simd_dot(calibratedUp, right))))
        return (offsetPitch, offsetRoll)
    }

    func requestUpdates(_ listener: InclinometerListener) {
        // widgets update from the map rendering thread, the timers and the motion queue live on the main one
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.requestUpdates(listener) }
            return
        }
        if !listeners.contains(where: { $0.listener === listener }) {
            listeners.append(WeakListener(listener))
        }
        startIfNeeded()
        if hasValue {
            listener.onInclinationChanged(pitch: pitch, roll: roll)
        }
    }

    func removeListener(_ listener: InclinometerListener) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.removeListener(listener) }
            return
        }
        listeners.removeAll { $0.listener === listener || $0.listener == nil }
        if listeners.isEmpty {
            stop()
        }
    }

    /// Stores the current device attitude as the level position of the vehicle.
    /// - Returns: false when no sensor reading is available yet
    @discardableResult
    func calibrate() -> Bool {
        guard hasValue else {
            return false
        }
        let up = simd_normalize(self.up)
        // Vehicle forward direction: top of the screen for a device lying flat,
        // back of the device for an upright one facing the driver; a blend covers the mounts in between
        let top = screenTopAxis()
        var forward = SIMD3<Float>(top.x, top.y, top.z - 1)
        forward -= up * simd_dot(forward, up)
        if simd_length(forward) < Self.minForwardProjection {
            forward = top
        }
        forward = simd_normalize(forward)

        calibratedUp = up
        calibratedForward = forward
        calibrationPref.set(String(format: "%.5f,%.5f,%.5f,%.5f,%.5f,%.5f",
                                   up.x, up.y, up.z, forward.x, forward.y, forward.z))
        computeInclination()
        notifyListeners()
        return true
    }

    func resetCalibration() {
        calibratedUp = nil
        calibratedForward = nil
        calibrationPref.resetToDefault()
        if hasValue {
            computeInclination()
            notifyListeners()
        }
    }

    // MARK: - Motion updates

    private func startIfNeeded() {
        guard !running, isSensorAvailable else {
            return
        }
        hasValue = false
        running = true
        if motionManager.isDeviceMotionAvailable {
            usingAccelerometer = false
            motionManager.deviceMotionUpdateInterval = Self.updateInterval
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self, let motion else { return }
                // CoreMotion gravity points towards the ground, the device "up" is the opposite
                self.onGravityChanged(SIMD3<Float>(-Float(motion.gravity.x), -Float(motion.gravity.y), -Float(motion.gravity.z)))
            }
        } else {
            usingAccelerometer = true
            motionManager.accelerometerUpdateInterval = Self.updateInterval
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.onGravityChanged(SIMD3<Float>(-Float(data.acceleration.x), -Float(data.acceleration.y), -Float(data.acceleration.z)))
            }
        }
        listenersCheckTimer = Timer.scheduledTimer(withTimeInterval: Self.listenersCheckInterval, repeats: true) { [weak self] _ in
            self?.removeInactiveListeners()
        }
    }

    private func stop() {
        guard running else {
            return
        }
        running = false
        hasValue = false
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        listenersCheckTimer?.invalidate()
        listenersCheckTimer = nil
    }

    private func onGravityChanged(_ value: SIMD3<Float>) {
        guard running else {
            return
        }
        if usingAccelerometer && hasValue {
            up += (value - up) * Self.accelerometerFilterAlpha
        } else {
            up = value
        }
        if simd_length(up) == 0 {
            return
        }
        hasValue = true
        computeInclination()
        notifyListeners()
    }

    private func computeInclination() {
        let up = simd_normalize(self.up)
        let forward: SIMD3<Float>
        let levelUp: SIMD3<Float>
        if let calibratedUp, let calibratedForward {
            levelUp = calibratedUp
            forward = calibratedForward
        } else {
            levelUp = SIMD3<Float>(0, 0, 1)
            forward = screenTopAxis()
        }
        let right = simd_cross(forward, levelUp)
        pitch = Self.clampAngle(Self.degrees(asin(Self.clampUnit(simd_dot(up, forward)))))
        roll = Self.clampAngle(-Self.degrees(asin(Self.clampUnit(simd_dot(up, right)))))
    }

    private func notifyListeners() {
        for wrapper in listeners {
            wrapper.listener?.onInclinationChanged(pitch: pitch, roll: roll)
        }
    }

    private func removeInactiveListeners() {
        listeners.removeAll { $0.listener == nil || !$0.listener!.isInclinometerActive }
        if listeners.isEmpty {
            stop()
        }
    }

    /// The device axis that points to the top of the screen in the current interface orientation
    private func screenTopAxis() -> SIMD3<Float> {
        switch ScreenOrientationHelper.sharedInstance.getCurrentInterfaceOrientation() {
        case .landscapeLeft:
            // Home button on the left: the device is turned clockwise, its left edge is at the top
            return SIMD3<Float>(-1, 0, 0)
        case .landscapeRight:
            return SIMD3<Float>(1, 0, 0)
        case .portraitUpsideDown:
            return SIMD3<Float>(0, -1, 0)
        default:
            return SIMD3<Float>(0, 1, 0)
        }
    }

    private func parseCalibration(_ value: String?) {
        guard let value, !value.isEmpty else {
            return
        }
        let parts = value.split(separator: ",").compactMap { Float($0) }
        guard parts.count == 6 else {
            NSLog("Invalid inclinometer calibration: %@", value)
            return
        }
        let up = SIMD3<Float>(parts[0], parts[1], parts[2])
        let forward = SIMD3<Float>(parts[3], parts[4], parts[5])
        if simd_length(up) > 0, simd_length(forward) > 0 {
            calibratedUp = simd_normalize(up)
            calibratedForward = simd_normalize(forward)
        }
    }

    // MARK: - Math

    // Slope angle to grade percent, as shown on road signs
    static func toPercent(_ degrees: Float) -> Float {
        tan(degrees * .pi / 180) * 100
    }

    private static func degrees(_ radians: Float) -> Float {
        radians * 180 / .pi
    }

    private static func clampAngle(_ degrees: Float) -> Float {
        max(-maxAngleDegrees, min(maxAngleDegrees, degrees))
    }

    private static func clampUnit(_ value: Float) -> Float {
        max(-1, min(1, value))
    }
}
