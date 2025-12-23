//
//  MapButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 24.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
open class MapButtonState: NSObject {
    static let originalValue: Int64 = -1
    static let rectangleRadiusDp: Int32 = 6
    static let defaultSizeDp: Int32 = 48
    static let roundRadiusDp: Int32 = 36
    static let opaqueAlpha: Float = 1
    
    private let settings: OAAppSettings = OAAppSettings.sharedManager()
    private let portraitPositionPref: OACommonLong
    private let landscapePositionPref: OACommonLong
    private let iconPref: OACommonString
    private let sizePref: OACommonInteger
    private let opacityPref: OACommonDouble
    private let cornerRadiusPref: OACommonInteger
    private let positionSize: ButtonPositionSize
    private let defaultPositionSize: ButtonPositionSize
    
    var portrait = true
    
    let id: String

    init(withId id: String) {
        self.id = id
        self.portraitPositionPref  = settings.registerLongPreference("\(id)_position_portrait", defValue: Int(Self.originalValue)).makeProfile()
        self.landscapePositionPref = settings.registerLongPreference("\(id)_position_landscape", defValue: Int(Self.originalValue)).makeProfile()
        iconPref = settings.registerStringPreference(id + "_icon", defValue: nil).makeProfile()
        sizePref = settings.registerIntPreference(id + "_size", defValue: Int32(Self.originalValue)).makeProfile()
        opacityPref = settings.registerFloatPreference(id + "_opacity", defValue: Double(Self.originalValue)).makeProfile()
        cornerRadiusPref = settings.registerIntPreference(id + "_corner_radius", defValue: Int32(Self.originalValue)).makeProfile()
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
    
    func createDefaultAppearanceParams() -> ButtonAppearanceParams {
        let buttonsHelper = OAMapButtonsHelper.sharedInstance()
        var size = buttonsHelper.getDefaultSizePref().get()
        if size <= 0 {
            size = defaultSize()
        }
        var opacity = Float(buttonsHelper.getDefaultOpacityPref().get())
        if opacity < 0 {
            opacity = defaultOpacity()
        }
        var cornerRadius = buttonsHelper.getDefaultCornerRadiusPref().get()
        if cornerRadius < 0 {
            cornerRadius = defaultCornerRadius()
        }
        return ButtonAppearanceParams(iconName: defaultIconName(), size: size, opacity: opacity, cornerRadius: cornerRadius)
    }
    
    func getName() -> String {
        fatalError("button state has no name")
    }

    func isEnabled() -> Bool {
        true
    }

    func getIcon() -> UIImage? {
        if let iconName = createAppearanceParams().iconName {
            return UIImage.templateImageNamed(iconName)
        } else {
            return UIImage.templateImageNamed("ic_custom_quick_action")
        }
    }
    
    func defaultIconName() -> String {
        fatalError("default icon has no name")
    }
    
    func getPreviewIcon() -> UIImage? {
        getIcon()
    }

    func getPositionSize() -> ButtonPositionSize {
        positionSize
    }

    func getDefaultPositionSize() -> ButtonPositionSize {
        let position = setupButtonPosition(defaultPositionSize)
        updatePosition(position)
        return position
    }
    
    func defaultSize() -> Int32 {
        Self.defaultSizeDp
    }
    
    func defaultOpacity() -> Float {
        Self.opaqueAlpha
    }

    func defaultCornerRadius() -> Int32 {
        Self.roundRadiusDp
    }
    
    func savedIconName() -> String {
        iconPref.get()
    }
    
    func storedIconPref() -> OACommonString {
        iconPref
    }
    
    func storedSizePref() -> OACommonInteger {
        sizePref
    }
    
    func storedOpacityPref() -> OACommonDouble {
        opacityPref
    }
    
    func storedCornerRadiusPref() -> OACommonInteger {
        cornerRadiusPref
    }
    
    func createAppearanceParams() -> ButtonAppearanceParams {
        let defaultParams = createDefaultAppearanceParams()
        var iconName: String? = savedIconName()
        if iconName == nil || iconName?.isEmpty == true {
            iconName = defaultParams.iconName
        }
        var size = sizePref.get()
        if size <= 0 {
            size = defaultParams.size
        }
        var opacity = Float(opacityPref.get())
        if opacity < 0 {
            opacity = defaultParams.opacity
        }
        var cornerRadius = cornerRadiusPref.get()
        if cornerRadius < 0 {
            cornerRadius = defaultParams.cornerRadius
        }
        return ButtonAppearanceParams(iconName: iconName, size: size, opacity: opacity, cornerRadius: cornerRadius)
    }
    
    func buttonDescription() -> String {
        fatalError("buttonDescription is not defined")
    }
    
    func storedVisibilityPref() -> OACommonPreference {
        fatalError("visibilityPref is not defined")
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
        iconPref.resetMode(toDefault: appMode)
        sizePref.resetMode(toDefault: appMode)
        opacityPref.resetMode(toDefault: appMode)
        cornerRadiusPref.resetMode(toDefault: appMode)
        portraitPositionPref.resetMode(toDefault: appMode)
        landscapePositionPref.resetMode(toDefault: appMode)
        storedVisibilityPref().resetMode(toDefault: appMode)
    }

    func copyForMode(from fromMode: OAApplicationMode, to toMode: OAApplicationMode) {
        iconPref.set(iconPref.get(fromMode), mode: toMode)
        sizePref.set(sizePref.get(fromMode), mode: toMode)
        opacityPref.set(opacityPref.get(fromMode), mode: toMode)
        cornerRadiusPref.set(cornerRadiusPref.get(fromMode), mode: toMode)
        portraitPositionPref.set(portraitPositionPref.get(fromMode), mode: toMode)
        landscapePositionPref.set(landscapePositionPref.get(fromMode), mode: toMode)
    }
    
    func hasCustomAppearance() -> Bool {
        createAppearanceParams() != createDefaultAppearanceParams()
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
