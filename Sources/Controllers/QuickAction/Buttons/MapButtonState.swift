//
//  MapButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
open class MapButtonState: NSObject {
    private static let originalValue: Int64 = -1
    private static let defaultSizeDp: Int32 = 48
    
    private let settings: OAAppSettings = OAAppSettings.sharedManager()
    private let portraitPositionPref: OACommonLong
    private let landscapePositionPref: OACommonLong
    private let positionSize: ButtonPositionSize
    private let defaultPositionSize: ButtonPositionSize
    
    var portrait = true
    
    let id: String

    init(withId id: String) {
        self.id = id
        self.portraitPositionPref  = settings.registerLongPreference("\(id)_position_portrait", defValue: Int(Self.originalValue)).makeProfile()
        self.landscapePositionPref = settings.registerLongPreference("\(id)_position_landscape", defValue: Int(Self.originalValue)).makeProfile()
        self.positionSize = ButtonPositionSize(id: id)
        self.defaultPositionSize = ButtonPositionSize(id: id)
        super.init()
        setupButtonPosition(positionSize)
        setupButtonPosition(defaultPositionSize)
    }
    
    func updatePosition(_ position: ButtonPositionSize) {
        let preference = portrait ? portraitPositionPref : landscapePositionPref
        let value = preference.get()
        if value > 0 {
            position.fromLongValue(v: Int64(value))
        }
        
        var size = Self.defaultSizeDp
        size = (size / 8) + 1
        position.setSize(width8dp: Int32(size), height8dp: Int32(size))
    }
    
    func getName() -> String {
        fatalError("button state has no name")
    }

    func isEnabled() -> Bool {
        true
    }

    func getIcon() -> UIImage? {
        UIImage.templateImageNamed("ic_custom_quick_action")
    }

    func getPositionSize() -> ButtonPositionSize {
        positionSize
    }

    func getDefaultPositionSize() -> ButtonPositionSize {
        let position = setupButtonPosition(defaultPositionSize)
        updatePosition(position)
        return position
    }

    @discardableResult func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        fatalError("setupButtonPosition(position:) must be overridden in subclass")
    }

    @discardableResult func setupButtonPosition(_ position: ButtonPositionSize, posH: Int32, posV: Int32, xMove: Bool, yMove: Bool) -> ButtonPositionSize {
        position.posH = posH
        position.posV = posV
        position.xMove = xMove
        position.yMove = yMove
        position.marginX = 0
        position.marginY = 0
        return position
    }

    func updatePositions() {
        portrait = OAUtilities.isPortrait()
        updatePosition(positionSize)
        updatePosition(defaultPositionSize)
    }

    func savePosition() {
        let pref = portrait ? portraitPositionPref : landscapePositionPref
        pref.set(Int(positionSize.toLongValue()))
    }

    func resetForMode(_ appMode: OAApplicationMode) {
        portraitPositionPref.resetMode(toDefault: appMode)
        landscapePositionPref.resetMode(toDefault: appMode)
    }

    func copyForMode(from fromMode: OAApplicationMode, to toMode: OAApplicationMode) {
        portraitPositionPref.set(portraitPositionPref.get(fromMode), mode: toMode)
        landscapePositionPref.set(landscapePositionPref.get(fromMode), mode: toMode)
    }
}

extension MapButtonState {
    static func javaCompatibleStringHash(of string: String) -> Int32 {
        var hash: Int32 = 0
        for codeUnit in string.utf16 {
            hash = 31 &* hash &+ Int32(bitPattern: UInt32(codeUnit))
        }
        
        return hash
    }
}
