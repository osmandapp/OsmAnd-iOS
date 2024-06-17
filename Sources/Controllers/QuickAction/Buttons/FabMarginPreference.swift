//
//  FabMarginPreference.swift
//  OsmAnd Maps
//
//  Created by Skalii on 26.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class FabMarginPreference: NSObject {

    private static let kXPortraitMargin = "_x_portrait_margin"
    private static let kYPortraitMargin = "_y_portrait_margin"
    private static let kXLandscapeMargin = "_x_landscape_margin"
    private static let kYLandscapeMargin = "_y_landscape_margin"

    let fabMarginXPortrait: OACommonInteger
    let fabMarginYPortrait: OACommonInteger
    let fabMarginXLandscape: OACommonInteger
    let fabMarginYLandscape: OACommonInteger

    private let settings = OAAppSettings.sharedManager()!

    init(_ prefix: String) {
        fabMarginXPortrait = settings.registerIntPreference(prefix + FabMarginPreference.kXPortraitMargin, defValue: 0).makeProfile()
        fabMarginYPortrait = settings.registerIntPreference(prefix + FabMarginPreference.kYPortraitMargin, defValue: 0).makeProfile()
        fabMarginXLandscape = settings.registerIntPreference(prefix + FabMarginPreference.kXLandscapeMargin, defValue: 0).makeProfile()
        fabMarginYLandscape = settings.registerIntPreference(prefix + FabMarginPreference.kYLandscapeMargin, defValue: 0).makeProfile()
    }

    func setPortraitFabMargin(x: Int32, y: Int32) {
        fabMarginXPortrait.set(x)
        fabMarginYPortrait.set(y)
    }

    func setLandscapeFabMargin(x: Int32, y: Int32) {
        fabMarginXLandscape.set(x)
        fabMarginYLandscape.set(y)
    }

    func setPortraitFabMargin(_ mode: OAApplicationMode, x: Int32, y: Int32) {
        fabMarginXPortrait.set(x, mode: mode)
        fabMarginYPortrait.set(y, mode: mode)
    }

    func setLandscapeFabMargin(_ mode: OAApplicationMode, x: Int32, y: Int32) {
        fabMarginXLandscape.set(x, mode: mode)
        fabMarginYLandscape.set(y, mode: mode)
    }

    func getPortraitFabMargin() -> [NSNumber] {
        getPortraitFabMargin(settings.applicationMode.get())
    }

    func getLandscapeFabMargin() -> [NSNumber] {
        getLandscapeFabMargin(settings.applicationMode.get())
    }

    func getPortraitFabMargin(_ mode: OAApplicationMode) -> [NSNumber] {
        [NSNumber(value: fabMarginXPortrait.get(mode)), NSNumber(value: fabMarginYPortrait.get(mode))]
    }

    func getLandscapeFabMargin(_ mode: OAApplicationMode) -> [NSNumber] {
        [NSNumber(value: fabMarginXLandscape.get(mode)), NSNumber(value: fabMarginYLandscape.get(mode))]
    }

    func resetMode(toDefault mode: OAApplicationMode) {
        fabMarginXPortrait.resetMode(toDefault: mode)
        fabMarginYPortrait.resetMode(toDefault: mode)
        fabMarginXLandscape.resetMode(toDefault: mode)
        fabMarginYLandscape.resetMode(toDefault: mode)
    }

    func copyForMode(fromMode: OAApplicationMode, toMode: OAApplicationMode) {
        fabMarginXPortrait.set(fabMarginXPortrait.get(fromMode), mode: toMode)
        fabMarginYPortrait.set(fabMarginYPortrait.get(fromMode), mode: toMode)
        fabMarginXLandscape.set(fabMarginXLandscape.get(fromMode), mode: toMode)
        fabMarginYLandscape.set(fabMarginYLandscape.get(fromMode), mode: toMode)
    }

    static func setFabButtonMargin(_ fabButton: UIButton, fabMargin: [Int32]?, defRightMargin: Int32, defBottomMargin: Int32) {
        let screenHeight = OAUtilities.calculateScreenHeight()
        let screenWidth = OAUtilities.calculateScreenWidth()
        let btnHeight = fabButton.frame.height
        let btnWidth = fabButton.frame.width
        let maxRightMargin = Int32(screenWidth - btnWidth)
        let maxBottomMargin = Int32(screenHeight - btnHeight)

        var rightMargin = fabMargin?.first ?? defRightMargin
        var bottomMargin = fabMargin?.last ?? defBottomMargin
        // check limits
        if rightMargin <= 0 {
            rightMargin = defRightMargin
        } else if rightMargin > maxRightMargin {
            rightMargin = maxRightMargin
        }
        if bottomMargin <= 0 {
            bottomMargin = defBottomMargin
        } else if bottomMargin > maxBottomMargin {
            bottomMargin = maxBottomMargin
        }

        fabButton.frame = CGRect(x: CGFloat(rightMargin),
                                 y: CGFloat(bottomMargin),
                                 width: fabButton.frame.size.width,
                                 height: fabButton.frame.size.height)
    }

    private static let kHudQuickActionButtonHeight: CGFloat = 50
    private static let kHudButtonsOffset: CGFloat = 16

    private var halfSmallButtonWidth: CGFloat {
        Self.kHudQuickActionButtonHeight / 2
    }

    private var leftMargin: CGFloat {
        OAUtilities.getLeftMargin() + Self.kHudButtonsOffset + halfSmallButtonWidth
    }

    private var rightMargin: CGFloat {
        OAUtilities.calculateScreenWidth() - OAUtilities.getLeftMargin() - Self.kHudButtonsOffset - halfSmallButtonWidth
    }

    private var topMargin: CGFloat {
        OAUtilities.getStatusBarHeight() + Self.kHudButtonsOffset + halfSmallButtonWidth
    }

    private var bottomMargin: CGFloat {
        OAUtilities.calculateScreenHeight() - OAUtilities.getBottomMargin() - Self.kHudButtonsOffset - halfSmallButtonWidth
    }

    func moveToPoint(_ newPosition: CGPoint, button: UIButton) {
        let halfBigButtonWidth = button.frame.size.width / 2

        var x = newPosition.x
        let leftMargin = leftMargin
        let rightMargin = rightMargin
        if x <= leftMargin {
            x = leftMargin
        } else if x >= rightMargin {
            x = rightMargin
        }

        var y = newPosition.y
        let topMargin = topMargin
        let bottomMargin = bottomMargin
        if y <= topMargin {
            y = topMargin
        } else if y >= bottomMargin {
            y = bottomMargin
        }

        button.frame = CGRect(x: x - halfBigButtonWidth,
                              y: y - halfBigButtonWidth,
                              width: button.frame.size.width,
                              height: button.frame.size.height)
    }

    func restorePosition(_ button: OAHudButton) {
        let isQuickActionButton = button.tag == OAUtilities.getQuickActionButtonTag()
        let isMap3DModeButton = button.tag == OAUtilities.getMap3DModeButtonTag()
        if OAUtilities.isLandscape() {
            let defaultX = rightMargin - (isQuickActionButton ? 2 : 1) * Self.kHudQuickActionButtonHeight - (isQuickActionButton ? 2 : 1) * Self.kHudButtonsOffset - halfSmallButtonWidth
            var defaultY = bottomMargin - halfSmallButtonWidth
            if isMap3DModeButton {
                defaultY -= (Self.kHudQuickActionButtonHeight + Self.kHudButtonsOffset)
            }
            let margins = getLandscapeFabMargin()
            var x = CGFloat(margins[0].floatValue)
            var y = CGFloat(margins[1].floatValue)
            setPositionForButton(button, x: &x, y: &y, defaultX: defaultX, defaultY: defaultY)
        } else {
            var defaultX = rightMargin - halfSmallButtonWidth
            if isMap3DModeButton {
                defaultX -= (Self.kHudQuickActionButtonHeight + Self.kHudButtonsOffset)
            }
            let defaultY = bottomMargin - (isQuickActionButton ? 2 : 1) * Self.kHudQuickActionButtonHeight - (isQuickActionButton ? 2 : 1) * Self.kHudButtonsOffset - halfSmallButtonWidth
            let margins = getPortraitFabMargin()
            var x = CGFloat(margins[0].floatValue)
            var y = CGFloat(margins[1].floatValue)
            setPositionForButton(button, x: &x, y: &y, defaultX: defaultX, defaultY: defaultY)
        }
    }

    private func setPositionForButton(_ button: OAHudButton,
                                      x: inout CGFloat,
                                      y: inout CGFloat,
                                      defaultX: CGFloat,
                                      defaultY: CGFloat) {

        let rightMargin = rightMargin
        if x <= 0 {
            x = defaultX
        } else if x > rightMargin {
            x = rightMargin
        }

        let bottomMargin = bottomMargin
        if y <= 0 {
            y = defaultY
        } else if y > bottomMargin {
            y = bottomMargin
        }

        button.frame = CGRect(x: x,
                              y: y,
                              width: button.frame.size.width,
                              height: button.frame.size.height)
    }
}
