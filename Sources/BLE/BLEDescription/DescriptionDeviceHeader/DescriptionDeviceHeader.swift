//
//  DescriptionDeviceHeader.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 09.10.2023.
//


import UIKit
import CoreBluetooth
import SwiftyBluetooth

final class DescriptionDeviceHeader: UIView {
    @IBOutlet private weak var imageContainerView: UIView!
    @IBOutlet private weak var deviceNameLabel: UILabel!
    @IBOutlet private weak var deviceImageView: UIImageView!
    @IBOutlet private weak var signalIndicatorImageView: UIImageView!
    @IBOutlet private weak var connectActivityView: UIActivityIndicatorView!
    @IBOutlet private weak var connectStatusLabel: UILabel!
    @IBOutlet private weak var connectButton: UIButton!
    
    var onUpdateConnectStateAction: ((CBPeripheralState) -> Void)? = nil
    var didPaireDevicedAction: (() -> Void)? = nil
    
    // DeviceHelper.shared.isPairedDevice(id: device.id)
    
    private var item: Device?
    
    // MARK: - Configure
    func configure(item: Device) {
        self.item = item
//        self.item?.didChangeCharacteristic = { [weak self] in
//            // Reload table
//
//        }
        deviceNameLabel.text = item.deviceName
        updateRSSI(with: item.rssi)
        configureConnectUI(item: item)
        configureStartStateActivityView(with: item.peripheral.state)
    }
    
    func updateRSSI(with signal: Int) {
        debugPrint("updateRSSI: \(signal)")
        signalIndicatorImageView.configureSignalImage(signal: signal)
    }
    
    private func configureStartStateActivityView(with state: CBPeripheralState) {
        switch state {
        case .connecting, .disconnecting:
            connectActivityView.startAnimating()
        default:
            connectActivityView.stopAnimating()
        }
    }
    
    private func configureConnectUI(item: Device) {
        switch item.peripheral.state {
        case .connected:
            connectStatusLabel.text = "Connected"
            signalIndicatorImageView.tintColor = UIColor.buttonBgColorPrimary
            updateRSSI(with: item.rssi)
            deviceImageView.image = item.getServiceConnectedImage
            configureConnectButtonTitle(with: .disconnected)
            imageContainerView.backgroundColor = UIColor.buttonBgColorTertiary
        default:
            connectStatusLabel.text = "Disconnected"
            signalIndicatorImageView.tintColor = UIColor.iconColorSecondary
            signalIndicatorImageView.image = UIImage(named: "ic_small_signal_not_found")
            deviceImageView.image = item.getServiceConnectedImage.noir
            configureConnectButtonTitle(with: .connected)
            imageContainerView.backgroundColor = UIColor.viewBgColor
        }
    }
    
    private func configureConnectButtonTitle(with state: CBPeripheralState) {
        connectButton.setTitle(state.description, for: .normal)
    }
    
    // MARK: - IBAction
    @IBAction func onConnectStatusButtonPressed(_ sender: Any) {
        guard let item else { return }
        switch item.peripheral.state {
        case .connected: disconnect()
        case .disconnected: connect()
        default: break
        }
    }
    
    private func connect() {
        guard let item else { return }
        configureConnectButtonTitle(with: .connecting)
        connectActivityView.startAnimating()
        item.peripheral.connect(withTimeout: 10) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                let isPairedDevice = DeviceHelper.shared.isPairedDevice(id: item.id)
                DeviceHelper.shared.setDevicePaired(device: item, isPaired: true)
                if !isPairedDevice {
                    didPaireDevicedAction?()
                }
                configureConnectButtonTitle(with: .disconnected)
                item.notifyRSSI()
                discoverServices(serviceUUIDs: nil)
                deviceImageView.image = item.getServiceConnectedImage
            case .failure(let error):
                configureConnectButtonTitle(with: .connected)
                showErrorAlertWith(message: error.localizedDescription)
            }
            update(with: item.peripheral.state)
        }
    }
    
    private func discoverServices(serviceUUIDs: [CBUUID]? = nil) {
        guard let item else { return }
        item.peripheral.discoverServices(withUUIDs: nil) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let services):
                discoverCharacteristics(services: services)
            case .failure(let error):
                debugPrint("discoverCharacteristics: \(error)")
                showErrorAlertWith(message: error.localizedDescription)
            }
        }
    }
    
    private func discoverCharacteristics(services: [CBService]) {
        guard let item else { return }
        for service in services {
            item.peripheral.discoverCharacteristics(withUUIDs: nil, ofServiceWithUUID: service.uuid) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let characteristics):
                    for characteristic in characteristics {
                        debugPrint(characteristic)
                        if characteristic.properties.contains(.read) {
                            item.update(with: characteristic) { [weak self] result in
                                if case .success = result {
#warning("reload data")
                                }
                            }
                        }
                        if characteristic.properties.contains(.notify) {
                            debugPrint("\(characteristic.uuid): properties contains .notify")
                            item.peripheral.setNotifyValue(toEnabled: true, ofCharac: characteristic) { result in
                                debugPrint(result)
                            }
                        }
                    }
                case .failure(let error):
                    debugPrint("discoverCharacteristics: \(error)")
                    showErrorAlertWith(message: error.localizedDescription)
                    break
                }
            }
        }
    }
    
    private func disconnect() {
        guard let item else { return }
        configureConnectButtonTitle(with: .disconnecting)
        connectActivityView.startAnimating()
        item.peripheral.disconnect { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                configureConnectButtonTitle(with: .connected)
                item.disableRSSI()
                deviceImageView.image = item.getServiceConnectedImage.noir
            case .failure(let error):
                configureConnectButtonTitle(with: .disconnected)
                showErrorAlertWith(message: error.localizedDescription)
            }
            update(with: item.peripheral.state)
        }
    }
    
    private func update(with state: CBPeripheralState) {
        guard let item else { return }
        configureConnectUI(item: item)
        connectActivityView.stopAnimating()
        onUpdateConnectStateAction?(state)
    }
    
    private func showErrorAlertWith(message: String) {
        debugPrint(message)
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .cancel))
        parentViewController?.present(alert, animated: true)
    }
}

extension CBPeripheralState {
    var description: String {
        switch self {
        case .disconnected: return "Disconnect"
        case .connecting: return "Connecting"
        case .connected: return "Connect"
        case .disconnecting: return "Disconnecting"
        @unknown default: return "Unknown"
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}
