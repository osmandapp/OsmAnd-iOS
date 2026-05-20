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

    var onUnavailable: ((_ message: String) -> Void)?
    private(set) var isRunning = false

    func startPreview(in hostView: UIView, below siblingView: UIView) {
        self.hostView = hostView
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configurePreview(in: hostView, below: siblingView)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configurePreview(in: hostView, below: siblingView)
                    } else {
                        self?.onUnavailable?(localizedString("astro_camera_permission_denied"))
                    }
                }
            }
        default:
            onUnavailable?(localizedString("astro_camera_permission_denied"))
        }
    }

    func stopPreview() {
        isRunning = false
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }

    func layoutPreview() {
        previewLayer?.frame = hostView?.bounds ?? .zero
    }

    private func configurePreview(in hostView: UIView, below siblingView: UIView) {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            onUnavailable?(localizedString("astro_camera_unavailable"))
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            let session = AVCaptureSession()
            session.sessionPreset = .high
            guard session.canAddInput(input) else {
                onUnavailable?(localizedString("astro_camera_unavailable"))
                return
            }
            session.addInput(input)

            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.opacity = 0.64
            layer.frame = hostView.bounds
            hostView.layer.insertSublayer(layer, below: siblingView.layer)

            captureSession = session
            previewLayer = layer
            isRunning = true
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        } catch {
            onUnavailable?(localizedString("astro_camera_unavailable"))
        }
    }
}

