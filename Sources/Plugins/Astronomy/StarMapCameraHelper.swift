//
//  StarMapCameraHelper.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import AVFoundation
import CoreMedia
import UIKit

final class StarMapCameraHelper {
    static let defaultTransparency = 50
    
    var onUnavailable: ((_ message: String) -> Void)?
    var onCameraStateChanged: ((_ enabled: Bool) -> Void)?
    
    private(set) var isCameraOverlayEnabled = false
    private(set) var calculatedFov = 60.0
    
    private let sessionQueue = DispatchQueue(label: "net.osmand.starMap.camera.session")
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var requestedTransparency = defaultTransparency
    private var rawCameraFov = 60.0
    private var cameraAspectRatio = 4.0 / 3.0
    private var lastPreviewBounds = CGRect.null
    private var lastVideoOrientation: AVCaptureVideoOrientation?
    
    private weak var hostView: UIView?
    private weak var siblingView: UIView?
    private weak var starView: StarView?

    func bind(starView: StarView) {
        self.starView = starView
    }

    func onResume() {
        if isCameraOverlayEnabled, let hostView, let siblingView {
            if !startPreview(in: hostView, below: siblingView) {
                disableCameraOverlay(notify: true)
                onUnavailable?(localizedString("recording_camera_not_available"))
            } else {
                starView?.setViewAngle(calculatedFov)
                updateCameraZoom(fov: calculatedFov)
            }
        }
    }

    func onPause() {
        closeCamera()
    }

    func toggleCameraOverlay(in hostView: UIView? = nil, below siblingView: UIView? = nil) {
        if let hostView, let siblingView {
            self.hostView = hostView
            self.siblingView = siblingView
        }
        if isCameraOverlayEnabled {
            disableCameraOverlay(notify: true)
        } else {
            requestCameraOverlay()
        }
    }

    func layoutPreview() {
        let bounds = hostView?.bounds ?? .zero
        let orientation = videoOrientation()
        let geometryChanged = lastPreviewBounds.size != bounds.size || lastVideoOrientation != orientation
        previewLayer?.frame = bounds
        updatePreviewOrientation(orientation)
        guard isCameraOverlayEnabled else {
            lastPreviewBounds = bounds
            lastVideoOrientation = orientation
            return
        }
        let currentViewAngle = starView?.getViewAngle()
        updateEffectiveFov()
        if geometryChanged {
            starView?.setViewAngle(calculatedFov)
            updateCameraZoom(fov: calculatedFov)
        } else if let currentViewAngle {
            updateCameraZoom(fov: currentViewAngle)
        }
        lastPreviewBounds = bounds
        lastVideoOrientation = orientation
    }

    func setTransparency(progress: Int) {
        requestedTransparency = max(0, min(100, progress))
        previewLayer?.opacity = Float(requestedTransparency) / 100.0
    }

    func resetFov() {
        starView?.setViewAngle(calculatedFov)
        updateCameraZoom(fov: calculatedFov)
        setTransparency(progress: Self.defaultTransparency)
    }

    func updateCameraZoom(fov: Double) {
        guard isCameraOverlayEnabled, let previewLayer else {
            return
        }
        let baseRad = calculatedFov * .pi / 180.0 / 2.0
        let targetRad = max(1, min(160, fov)) * .pi / 180.0 / 2.0
        let scale = CGFloat(tan(baseRad) / tan(targetRad))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
        CATransaction.commit()
    }

    private func requestCameraOverlay() {
        guard let hostView, let siblingView else {
            onUnavailable?(localizedString("recording_camera_not_available"))
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            enableCameraOverlay(in: hostView, below: siblingView)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else {
                        return
                    }
                    if granted, !self.isCameraOverlayEnabled {
                        self.enableCameraOverlay(in: hostView, below: siblingView)
                    } else if !granted {
                        self.onUnavailable?(localizedString("no_camera_permission"))
                    }
                }
            }
        default:
            onUnavailable?(localizedString("no_camera_permission"))
        }
    }

    private func enableCameraOverlay(in hostView: UIView, below siblingView: UIView) {
        guard !isCameraOverlayEnabled else {
            return
        }
        guard startPreview(in: hostView, below: siblingView) else {
            onUnavailable?(localizedString("recording_camera_not_available"))
            return
        }
        isCameraOverlayEnabled = true
        starView?.setViewAngle(calculatedFov)
        onCameraStateChanged?(true)
    }

    private func disableCameraOverlay(notify: Bool) {
        let wasEnabled = isCameraOverlayEnabled
        isCameraOverlayEnabled = false
        closeCamera()
        if notify && wasEnabled {
            onCameraStateChanged?(false)
        }
    }
    
    private func startPreview(in hostView: UIView, below siblingView: UIView) -> Bool {
        assert(Thread.isMainThread)
        self.hostView = hostView
        self.siblingView = siblingView
        
        sessionQueue.sync { [weak self] in
            guard let self, let session = self.captureSession, session.isRunning else { return }
            session.stopRunning()
        }
        captureSession = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        do {
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                return false
            }
            let input = try AVCaptureDeviceInput(device: camera)
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .high
            guard session.canAddInput(input) else {
                session.commitConfiguration()
                return false
            }
            session.addInput(input)
            session.commitConfiguration()
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.opacity = Float(requestedTransparency) / 100.0
            layer.frame = hostView.bounds
            hostView.layer.insertSublayer(layer, below: siblingView.layer)
            let fovInfo = cameraFovInfo(camera)
            rawCameraFov = fovInfo.width
            cameraAspectRatio = fovInfo.aspectRatio
            captureSession = session
            previewLayer = layer
            lastPreviewBounds = hostView.bounds
            lastVideoOrientation = videoOrientation()
            updatePreviewOrientation(lastVideoOrientation)
            updateEffectiveFov()
            sessionQueue.async { [weak self] in
                guard self?.captureSession === session else { return }
                session.startRunning()
            }
            return true
        } catch {
            return false
        }
    }

    private func closeCamera() {
        let session = captureSession
        captureSession = nil
        
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        
        lastPreviewBounds = .null
        lastVideoOrientation = nil
        
        guard let session else { return }
        
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func updateEffectiveFov() {
        calculatedFov = calculateEffectiveFov()
    }

    private func calculateEffectiveFov() -> Double {
        guard let hostView else {
            return rawCameraFov
        }
        let bounds = hostView.bounds
        guard bounds.width > 0, bounds.height > 0 else {
            return rawCameraFov
        }
        let isLandscape = bounds.width >= bounds.height
        let baseFovForX = isLandscape ? rawCameraFov : cameraVerticalFov()
        let imageAspect = CGFloat(isLandscape ? cameraAspectRatio : 1.0 / cameraAspectRatio)
        let aspectFillWidth = max(bounds.width, bounds.height * imageAspect)
        let scaleX = max(1.0, Double(aspectFillWidth / bounds.width))
        let halfFovRad = baseFovForX * .pi / 180.0 / 2.0
        let effectiveRad = 2.0 * atan(tan(halfFovRad) / scaleX)
        return effectiveRad * 180.0 / .pi
    }

    private func cameraVerticalFov() -> Double {
        let halfFovRad = rawCameraFov * .pi / 180.0 / 2.0
        return 2.0 * atan(tan(halfFovRad) / cameraAspectRatio) * 180.0 / .pi
    }

    private func cameraFovInfo(_ camera: AVCaptureDevice) -> (width: Double, aspectRatio: Double) {
        let fieldOfView = camera.activeFormat.videoFieldOfView > 0 ? Double(camera.activeFormat.videoFieldOfView) : 60.0
        let dimensions = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
        let width = Double(max(dimensions.width, dimensions.height))
        let height = Double(min(dimensions.width, dimensions.height))
        guard width > 0, height > 0 else {
            return (fieldOfView, 4.0 / 3.0)
        }
        return (fieldOfView, width / height)
    }

    private func updatePreviewOrientation(_ orientation: AVCaptureVideoOrientation? = nil) {
        guard let connection = previewLayer?.connection, connection.isVideoOrientationSupported else {
            return
        }
        connection.videoOrientation = orientation ?? videoOrientation()
    }

    private func videoOrientation() -> AVCaptureVideoOrientation {
        switch ScreenOrientationHelper.sharedInstance.getCurrentInterfaceOrientation() {
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}
