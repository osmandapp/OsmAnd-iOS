//
//  ScreenOrientationHelper.swift
//  OsmAnd Maps
//
//  Created by Skalii on 30.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAScreenOrientationHelper)
@objcMembers
class ScreenOrientationHelper: NSObject {
    static let sharedInstance: ScreenOrientationHelper = ScreenOrientationHelper()
    static let screenOrientationChangedKey: String = "screenOrientationChangedKey"
    
    private let settings = OAAppSettings.sharedManager()
    
    private var cachedUserInterfaceOrientationMask: UIInterfaceOrientationMask = .all
    private var cachedCurrentInterfaceOrientation: UIInterfaceOrientation = .portrait
    private var applicationModeChangedObserver: OAAutoObserverProxy?
    
    // MARK: Initialization
    
    override init() {
        super.init()
        updateCachedUserInterfaceOrientationMask()
        updateCachedCurrentInterfaceOrientation()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onProfileSettingDidChange),
                                               name: NSNotification.Name(kNotificationSetProfileSetting),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDeviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)

        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let applicationModeChangedSelector = #selector(onApplicationModeChanged as () -> Void)
        applicationModeChangedObserver = OAAutoObserverProxy(self, withHandler: applicationModeChangedSelector, andObserve: app.applicationModeChangedObservable)
    }
    
    deinit {
        applicationModeChangedObserver?.detach()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Settings

    func isPortrait() -> Bool {
        cachedCurrentInterfaceOrientation.isPortrait
    }
    
    func isLandscape() -> Bool {
        cachedCurrentInterfaceOrientation.isLandscape
    }
    
    func getUserInterfaceOrientationMask() -> UIInterfaceOrientationMask {
        cachedUserInterfaceOrientationMask
    }
    
    func getCurrentInterfaceOrientation() -> UIInterfaceOrientation {
        cachedCurrentInterfaceOrientation
    }

    // MARK: Updates

    func updateSettings() {
        updateCachedUserInterfaceOrientationMask()
        updateDeviceOrientation()
    }

    private func updateDeviceOrientation() {
        updateCachedCurrentInterfaceOrientation()
        NotificationCenter.default.post(name: NSNotification.Name(Self.screenOrientationChangedKey), object: nil)
    }

    private func updateCachedUserInterfaceOrientationMask() {
        let mapScreenOrientation: Int32 = settings?.mapScreenOrientation.get() ?? Int32(EOAScreenOrientation.system.rawValue)
        cachedUserInterfaceOrientationMask =
            mapScreenOrientation == EOAScreenOrientation.portrait.rawValue ? .portrait
            : mapScreenOrientation == EOAScreenOrientation.landscape.rawValue ? .landscape
            : .all
    }
    
    private func updateCachedCurrentInterfaceOrientation() {
        let userOrientation: UIInterfaceOrientationMask = getUserInterfaceOrientationMask()
        let systemOrientation: UIInterfaceOrientation = (UIApplication.shared.delegate as? OAAppDelegate)?.interfaceOrientation ?? .unknown
        if userOrientation != .all {
            if userOrientation == .landscape {
                cachedCurrentInterfaceOrientation = systemOrientation.isLandscape ? systemOrientation : .landscapeLeft
                return
            } else if userOrientation == .portrait {
                cachedCurrentInterfaceOrientation = systemOrientation.isPortrait ? systemOrientation : .portrait
                return
            }
        }
        
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portraitUpsideDown:
            cachedCurrentInterfaceOrientation = .portraitUpsideDown
        case .landscapeLeft:
            cachedCurrentInterfaceOrientation = .landscapeLeft
        case .landscapeRight:
            cachedCurrentInterfaceOrientation = .landscapeRight
        case .portrait:
            cachedCurrentInterfaceOrientation = .portrait
        case .faceUp, .faceDown:
            return
        default:
            cachedCurrentInterfaceOrientation = .portrait
        }
    }
    
    // MARK: Selectors

    @objc private func onApplicationModeChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updateSettings()
        }
    }

    @objc private func onProfileSettingDidChange(notification: Notification) {
        if let obj = notification.object as? OACommonPreference, obj == settings?.mapScreenOrientation {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.updateCachedUserInterfaceOrientationMask()
                self.updateDeviceOrientation()
            }
        }
    }

    @objc private func onDeviceOrientationDidChange() {
        updateDeviceOrientation()
    }
}
