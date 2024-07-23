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
class ScreenOrientationHelper : NSObject {
    
    private let settings = OAAppSettings.sharedManager()
    
    private var cachedUserInterfaceOrientationMask: UIInterfaceOrientationMask = .all
    private var cachedCurrentInterfaceOrientation: UIInterfaceOrientation = .portrait
    
    private static var sharedHelperInstance: ScreenOrientationHelper?
    static let screenOrientationChangedKey: String = "screenOrientationChangedKey"

    private var applicationModeChangedObserver: OAAutoObserverProxy?

    //MARK: Initialization

    static var sharedInstance: ScreenOrientationHelper {
        get {
            if sharedHelperInstance == nil {
                sharedHelperInstance = ScreenOrientationHelper()
            }
            return sharedHelperInstance!
        }
    }
    
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
        applicationModeChangedObserver = OAAutoObserverProxy(self, withHandler: applicationModeChangedSelector, andObserve: app.data.applicationModeChangedObservable)
    }
    
    deinit {
        applicationModeChangedObserver?.detach()
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: Settings

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

    //MARK: Updates

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
        let systemiOrientation: UIInterfaceOrientation = (UIApplication.shared.delegate as? OAAppDelegate)?.interfaceOrientation ?? .unknown
        if userOrientation != .all {
            if userOrientation == .landscape {
                cachedCurrentInterfaceOrientation = systemiOrientation.isLandscape ? systemiOrientation : .landscapeLeft
                return
            } else if userOrientation == .portrait {
                cachedCurrentInterfaceOrientation = systemiOrientation.isPortrait ? systemiOrientation : .portrait
                return
            }
        }
        
        let deviceOrietation: UIDeviceOrientation = UIDevice.current.orientation
        if deviceOrietation == .portraitUpsideDown {
            cachedCurrentInterfaceOrientation = .portraitUpsideDown
        } else if deviceOrietation == .landscapeLeft {
            cachedCurrentInterfaceOrientation = .landscapeLeft
        } else if deviceOrietation == .landscapeRight {
            cachedCurrentInterfaceOrientation = .landscapeRight
        } else {
            cachedCurrentInterfaceOrientation = .portrait
        }
    }
    
    //MARK: Selectors

    @objc private func onApplicationModeChanged() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updateSettings()
        }
    }

    @objc private func onProfileSettingDidChange(notification: Notification) {
        if let obj = notification.object as? OACommonPreference, obj == settings?.mapScreenOrientation {
            updateCachedUserInterfaceOrientationMask()
            updateDeviceOrientation()
        }
    }

    @objc private func onDeviceOrientationDidChange() {
        updateDeviceOrientation()
    }

}
