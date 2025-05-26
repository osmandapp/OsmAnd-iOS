//
//  DescriptionDeviceHeader.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//

import UIKit
import CoreBluetooth

final class DescriptionDeviceHeader: UIView {
    @IBOutlet private weak var imageContainerView: UIView!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var signalIndicatorImageView: UIImageView!
    @IBOutlet private weak var connectActivityView: UIActivityIndicatorView!
    @IBOutlet private weak var connectStatusLabel: UILabel!
    @IBOutlet private weak var connectButton: UIButton!
    
    var onUpdateConnectStateAction: ((DeviceState) -> Void)?
    var didPairedDeviceAction: (() -> Void)?
    
    private var device: Device?
    
    // MARK: - Configure
    func configure(device: Device) {
        self.device = device
        deviceNameLabel.text = device.deviceName
        updateRSSI(with: device.rssi)
        configureConnectUI(device: device)
        configureStartStateActivityView(with: device.state)
        if BLEManager.shared.getBluetoothState() != .poweredOn {
            debugPrint("getBluetoothState: is not active")
            changeDisconnectedState(device: device)
        }
    }
    
    func updateActiveServiceImage() {
        guard let device else { return }
        deviceImageView.image = device.getServiceConnectedImage
    }
    
    private func changeDisconnectedState(device: Device) {
        configureConnectButtonTitle(with: .connected)
        deviceImageView.image = device.getServiceDisconnectedImage
        deviceImageView.tintColor = .iconColorDefault
        connectActivityView.stopAnimating()
        configureStartStateActivityView(with: device.state)
    }
    
    func updateRSSI(with signal: Int) {
        debugPrint("updateRSSI: \(signal)")
        signalIndicatorImageView.configureSignalImage(signal: signal)
    }
    
    private func configureStartStateActivityView(with state: DeviceState) {
        switch state {
        case .connecting, .disconnecting:
            connectActivityView.startAnimating()
        default:
            connectActivityView.stopAnimating()
        }
    }
    
    private func configureConnectUI(device: Device) {
        if device.isConnected {
            connectStatusLabel.text = localizedString("external_device_status_connected")
            signalIndicatorImageView.tintColor = .buttonBgColorPrimary
            updateRSSI(with: device.rssi)
            deviceImageView.image = device.getServiceConnectedImage
            configureConnectButtonTitle(with: .disconnected)
            imageContainerView.backgroundColor = .buttonBgColorTertiary
        } else {
            connectStatusLabel.text = localizedString("external_device_status_disconnected")
            signalIndicatorImageView.tintColor = UIColor.iconColorSecondary
            signalIndicatorImageView.image = UIImage(named: "ic_small_signal_not_found")
            deviceImageView.image = device.getServiceDisconnectedImage
            deviceImageView.tintColor = .iconColorDefault
            configureConnectButtonTitle(with: .connected)
            imageContainerView.backgroundColor = .viewBg
        }
    }
    
    private func configureConnectButtonTitle(with state: DeviceState) {
        connectButton.setTitle(state.description, for: .normal)
    }
    
    private func connect() {
        guard let device else { return }
        configureConnectButtonTitle(with: .connecting)
        connectActivityView.startAnimating()
        device.connect(withTimeout: 10) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                NSLog("connect success | \(device.deviceServiceName) | \(device.deviceName)")
                let isPairedDevice = DeviceHelper.shared.isPairedDevice(id: device.id)
                DeviceHelper.shared.setDevicePaired(device: device, isPaired: true)
                DeviceHelper.shared.addConnected(device: device)
                if !isPairedDevice {
                    didPairedDeviceAction?()
                }
                configureConnectButtonTitle(with: .disconnected)
                discoverServices(serviceUUIDs: nil)
                deviceImageView.image = device.getServiceConnectedImage
            case .failure(let error):
                if let error = error as? SBError {
                    switch error {
                    case .invalidPeripheral:
                        changeDisconnectedState(device: device)
                    default: break
                    }
                }
                configureConnectButtonTitle(with: .connected)
                showErrorAlertWith(message: error.localizedDescription)
            }
            update(with: device.state)
        }
    }
    
    private func discoverServices(serviceUUIDs: [CBUUID]? = nil) {
        guard let device else { return }
        device.discoverServices(withUUIDs: nil) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let services):
                NSLog("discoverCharacteristics: success")
                discoverCharacteristics(services: services)
            case .failure(let error):
                NSLog("discoverCharacteristics: \(error)")
                showErrorAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    private func discoverCharacteristics(services: [CBService]) {
        guard let device else { return }
        var completedCount = 0
        let totalServices = services.count
        for service in services {
            device.discoverCharacteristics(withUUIDs: nil, ofServiceWithUUID: service.uuid) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let characteristics):
                    for characteristic in characteristics {
                        debugPrint(characteristic)
                        if characteristic.properties.contains(.read) {
                            device.update(with: characteristic) { _ in }
                        }
                        if characteristic.properties.contains(.notify) {
                            NSLog("\(characteristic.uuid): properties contains .notify")
                            device.setNotifyValue(toEnabled: true, ofCharac: characteristic) { notifyResult in
                                switch notifyResult {
                                case .success(let isNotifying):
                                    NSLog("success: this peripheral was registered for change notifications to the characteristic [\(characteristic.uuid)]: \(isNotifying)")
                                case .failure(let error):
                                    NSLog("failure: this peripheral was not registered for change notifications to the characteristic [\(characteristic.uuid)]:  \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    completedCount += 1
                    if completedCount == totalServices {
                        if device.deviceType == .OBD_VEHICLE_METRICS {
                            OBDService.shared.startDispatcher()
                        }
                    }
                case .failure(let error):
                    NSLog("discoverCharacteristics: \(error)")
                    showErrorAlertWith(message: error.localizedDescription)
                    completedCount += 1
                }
            }
        }
    }
        
    private func disconnect() {
        guard let device else { return }
        configureConnectButtonTitle(with: .disconnecting)
        connectActivityView.startAnimating()
        device.disableRSSI()
        device.disconnect { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                DeviceHelper.shared.removeDisconnected(device: device)
                configureConnectButtonTitle(with: .connected)
                deviceImageView.image = device.getServiceDisconnectedImage
                deviceImageView.tintColor = .iconColorDefault
            case .failure(let error):
                if let error = error as? SBError {
                    switch error {
                    case .invalidPeripheral:
                        changeDisconnectedState(device: device)
                    default: break
                    }
                }
                configureConnectButtonTitle(with: .disconnected)
                showErrorAlertWith(message: error.localizedDescription)
            }
            update(with: device.state)
        }
    }
    
    private func update(with state: DeviceState) {
        guard let device else { return }
        configureConnectUI(device: device)
        connectActivityView.stopAnimating()
        onUpdateConnectStateAction?(state)
    }
    
    private func showErrorAlertWith(message: String) {
        debugPrint(message)
        let alert = UIAlertController(title: localizedString("osm_failed_uploads"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .cancel))
        parentViewController?.present(alert, animated: true)
    }
    
    // MARK: - IBAction
    @IBAction private func onConnectStatusButtonPressed(_ sender: Any) {
        guard let device else { return }
        switch device.state {
        case .connected: disconnect()
        case .disconnected: connect()
        default: break
        }
    }
}
