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
    private var cachedCurrentInterfaceOrientation: UIInterfaceOrientation = .unknown
    
    private static var sharedHelperInstance: ScreenOrientationHelper?
    static let screenOrientationChangedKey: String = "screenOrientationChangedKey"
    static let applicationModeChangedKey: String = "applicationModeChangedKey"
    
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
        updateUserInterfaceOrientationMask()
        updateCurrentInterfaceOrientation()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onUserOrientationDidChange),
                                               name: NSNotification.Name(kNotificationSetProfileSetting),
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onDeviceOrientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onApplicationModeChanged),
                                               name: NSNotification.Name(Self.applicationModeChangedKey),
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func onApplicationModeChanged() {
        updateUserInterfaceOrientationMask()
        onDeviceOrientationDidChange()
    }
    
    @objc private func onUserOrientationDidChange(notification: Notification) {
        if let obj = notification.object as? OACommonPreference, obj == settings?.mapScreenOrientation {
            updateUserInterfaceOrientationMask()
            onDeviceOrientationDidChange()
        }
    }
    
    @objc private func onDeviceOrientationDidChange() {
        updateCurrentInterfaceOrientation()
        NotificationCenter.default.post(name: NSNotification.Name(Self.screenOrientationChangedKey), object: nil)
    }
    
    func isPortrait() -> Bool {
        cachedCurrentInterfaceOrientation.isPortrait
    }
    
    func isLandscape() -> Bool {
        cachedCurrentInterfaceOrientation.isLandscape
    }
    
    func getUserInterfaceOrientationMask() -> UIInterfaceOrientationMask {
        cachedUserInterfaceOrientationMask
    }
    
    private func updateUserInterfaceOrientationMask() {
        let mapScreenOrientation: Int32 = settings?.mapScreenOrientation.get() ?? Int32(EOAScreenOrientation.system.rawValue)
        cachedUserInterfaceOrientationMask =
            mapScreenOrientation == EOAScreenOrientation.portrait.rawValue ? .portrait
            : mapScreenOrientation == EOAScreenOrientation.landscape.rawValue ? .landscape
            : .all
    }
    
    func getCurrentInterfaceOrientation() -> UIInterfaceOrientation {
        return cachedCurrentInterfaceOrientation
    }
    
    private func updateCurrentInterfaceOrientation() {
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
        if deviceOrietation == .portrait {
            cachedCurrentInterfaceOrientation = .portrait
        } else if deviceOrietation == .portraitUpsideDown {
            cachedCurrentInterfaceOrientation = .portraitUpsideDown
        } else if deviceOrietation == .landscapeLeft {
            cachedCurrentInterfaceOrientation = .landscapeLeft
        } else if deviceOrietation == .landscapeRight {
            cachedCurrentInterfaceOrientation = .landscapeRight
        } else {
            cachedCurrentInterfaceOrientation = .unknown
        }
    }
    
}
