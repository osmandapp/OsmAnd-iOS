//
//  StarMapCameraHelper.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import AVFoundation
import UIKit

final class StarMapCameraHelper {
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private weak var hostView: UIView?
    private weak var siblingView: UIView?
    private weak var starView: StarView?
    private var requestedTransparency = 64
    private var baseFov = 60.0

    var onUnavailable: ((_ message: String) -> Void)?
    var onCameraStateChanged: ((_ enabled: Bool) -> Void)?
    private(set) var isCameraOverlayEnabled = false
    private(set) var calculatedFov = 60.0
    private(set) var isRunning = false

    static let permissionRequestCamera = 1001

    func bind(starView: StarView) {
        self.starView = starView
    }

    func onResume() {
        if isCameraOverlayEnabled, let hostView, let siblingView {
            startPreview(in: hostView, below: siblingView)
        }
    }

    func onPause() {
        closeCamera()
    }

    func onRequestPermissionsResult(requestCode: Int, grantResults: [Bool]) {
        guard requestCode == Self.permissionRequestCamera else {
            return
        }
        if grantResults.first == true {
            toggleCameraOverlay()
        } else {
            onUnavailable?(localizedString("astro_camera_permission_denied"))
        }
    }

    func toggleCameraOverlay(in hostView: UIView? = nil, below siblingView: UIView? = nil) {
        if let hostView, let siblingView {
            self.hostView = hostView
            self.siblingView = siblingView
        }
        isCameraOverlayEnabled.toggle()
        if isCameraOverlayEnabled {
            guard let hostView = self.hostView, let siblingView = self.siblingView else {
                isCameraOverlayEnabled = false
                onCameraStateChanged?(false)
                onUnavailable?(localizedString("astro_camera_unavailable"))
                return
            }
            calculatedFov = calculateCameraFov()
            startPreview(in: hostView, below: siblingView)
        } else {
            stopPreview()
        }
        starView?.isCameraMode = isCameraOverlayEnabled
        onCameraStateChanged?(isCameraOverlayEnabled)
    }

    func startPreview(in hostView: UIView, below siblingView: UIView) {
        self.hostView = hostView
        self.siblingView = siblingView
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configurePreview(in: hostView, below: siblingView)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configurePreview(in: hostView, below: siblingView)
                    } else {
                        self?.isCameraOverlayEnabled = false
                        self?.onCameraStateChanged?(false)
                        self?.onUnavailable?(localizedString("astro_camera_permission_denied"))
                    }
                }
            }
        default:
            isCameraOverlayEnabled = false
            onCameraStateChanged?(false)
            onUnavailable?(localizedString("astro_camera_permission_denied"))
        }
    }

    func stopPreview() {
        isCameraOverlayEnabled = false
        isRunning = false
        closeCamera()
        onCameraStateChanged?(false)
    }

    func layoutPreview() {
        previewLayer?.frame = hostView?.bounds ?? .zero
        if isCameraOverlayEnabled {
            updateEffectiveFov(scaleX: currentPreviewScale(), baseFov: baseFov)
        }
    }

    func setTransparency(progress: Int) {
        requestedTransparency = max(0, min(100, progress))
        previewLayer?.opacity = Float(requestedTransparency) / 100.0
    }

    func resetFov() {
        calculatedFov = calculateCameraFov()
        starView?.setViewAngle(calculatedFov)
    }

    func updateCameraZoom(fov: Double) {
        guard isCameraOverlayEnabled, let previewLayer else {
            return
        }
        let baseRad = baseFov * .pi / 180.0 / 2.0
        let targetRad = max(1, min(160, fov)) * .pi / 180.0 / 2.0
        let scale = CGFloat(tan(baseRad) / tan(targetRad))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        CATransaction.commit()
    }

    func calculateCameraFov() -> Double {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return 60.0
        }
        return calculateSensorFov(camera)
    }

    private func updateEffectiveFov(scaleX: CGFloat, baseFov: Double) {
        let halfFovRad = baseFov * .pi / 180.0 / 2.0
        let effectiveRad = 2.0 * atan(tan(halfFovRad) / Double(max(0.1, scaleX)))
        calculatedFov = effectiveRad * 180.0 / .pi
        if isCameraOverlayEnabled {
            starView?.setViewAngle(calculatedFov)
        }
    }

    private func configurePreview(in hostView: UIView, below siblingView: UIView) {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            isCameraOverlayEnabled = false
            onCameraStateChanged?(false)
            onUnavailable?(localizedString("astro_camera_unavailable"))
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            let session = AVCaptureSession()
            session.sessionPreset = .high
            guard session.canAddInput(input) else {
                isCameraOverlayEnabled = false
                onCameraStateChanged?(false)
                onUnavailable?(localizedString("astro_camera_unavailable"))
                return
            }
            session.addInput(input)

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.opacity = Float(requestedTransparency) / 100.0
            layer.frame = hostView.bounds
            hostView.layer.insertSublayer(layer, below: siblingView.layer)

            baseFov = calculateSensorFov(camera)
            calculatedFov = baseFov
            captureSession = session
            previewLayer = layer
            isCameraOverlayEnabled = true
            isRunning = true
            updateEffectiveFov(scaleX: currentPreviewScale(), baseFov: baseFov)
            onCameraStateChanged?(true)
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            isCameraOverlayEnabled = false
            onCameraStateChanged?(false)
            onUnavailable?(localizedString("astro_camera_unavailable"))
        }
    }

    private func closeCamera() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        isRunning = false
    }

    private func currentPreviewScale() -> CGFloat {
        guard let hostView else {
            return 1
        }
        let bounds = hostView.bounds
        guard bounds.width > 0, bounds.height > 0 else {
            return 1
        }
        return max(bounds.width, bounds.height) / min(bounds.width, bounds.height)
    }

    private func calculateSensorFov(_ camera: AVCaptureDevice) -> Double {
        guard camera.activeFormat.videoFieldOfView > 0 else {
            return 60.0
        }
        return Double(camera.activeFormat.videoFieldOfView)
    }
}
