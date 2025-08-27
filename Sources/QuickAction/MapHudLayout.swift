//
//  MapHudLayout.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class MapHudLayout: NSObject {
    private let containerView: UIView
    private let dpToPx: CGFloat = 1.0
    private let hudBasePaddingDp: CGFloat = 16.0
    private let tablet: Bool
    
    private var statusBarHeight: CGFloat
    private var portrait: Bool
    private var lastWidth: CGFloat = 0
    private var mapButtons: [OAHudButton] = []
    private var widgetPositions: [UIView: ButtonPositionSize] = [:]
    private var additionalWidgetPositions: [UIView: ButtonPositionSize] = [:]
    private var widgetOrder: [UIView] = []
    private var additionalOrder: [UIView] = []
    private var externalTopOverlayPx: CGFloat = 0
    private var externalBottomOverlayPx: CGFloat = 0
    private var ignoreTopSidePanels: Bool = false
    private var ignoreBottomSidePanels: Bool = false
    
    private weak var topBarPanelContainer: UIView?
    private weak var leftWidgetsPanel: UIView?
    private weak var rightWidgetsPanel: UIView?
    private weak var bottomBarPanelContainer: UIView?
    
    init(containerView: UIView) {
        self.containerView = containerView
        self.tablet = OAUtilities.isIPad()
        self.portrait = OAUtilities.isPortrait()
        self.statusBarHeight = OAUtilities.getStatusBarHeight()
        super.init()
    }
    
    private func addPosition(_ view: UIView?) {
        guard let view else { return }
        widgetPositions[view] = createWidgetPosition(view)
        if !widgetOrder.contains(view) {
            widgetOrder.append(view)
        }
    }
    
    private func refresh() {
        if Thread.isMainThread {
            updateButtons()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.updateButtons()
            }
        }
    }
    
    private func getButtonPositionSizes() -> [UIView: ButtonPositionSize] {
        let panels = [topBarPanelContainer, leftWidgetsPanel, rightWidgetsPanel, bottomBarPanelContainer]
        var filtered = collectPositionsOrdered().filter { (v, _) in
            guard panels.contains(where: { $0 === v }) else { return true }
            return !v.isHidden && v.alpha > 0.01 && v.bounds.width > 0 && v.bounds.height > 0
        }
        
        if filtered.contains(where: { $0.0 is OADownloadMapWidget }), let topBarPanelContainer {
            filtered.removeAll { (v, _) in v === topBarPanelContainer }
        }
        
        if ignoreTopSidePanels {
            if let topBarPanelContainer {
                filtered.removeAll { $0.0 === topBarPanelContainer }
            }
            
            if let leftWidgetsPanel {
                filtered.removeAll { $0.0 === leftWidgetsPanel }
            }
            
            if let rightWidgetsPanel {
                filtered.removeAll { $0.0 === rightWidgetsPanel }
            }
        }
        
        if ignoreBottomSidePanels {
            if let bottomBarPanelContainer {
                filtered.removeAll { $0.0 === bottomBarPanelContainer }
            }
        }
        
        let insets = containerView.safeAreaInsets
        let cell = CGFloat(ButtonPositionSize.Companion().CELL_SIZE_DP)
        let w = Int32(max(1, floor((containerView.bounds.width - insets.left - insets.right) / dpToPx / cell)))
        let h = Int32(max(1, floor(getAdjustedHeight() / dpToPx / cell)))
        ButtonPositionSize.Companion().computeNonOverlap(space: 1, buttons: filtered.map { $0.1 }, totalWidth: w, totalHeight: h)
        var map: [UIView: ButtonPositionSize] = [:]
        for (v, p) in filtered {
            map[v] = p
        }
        
        return map
    }
    
    private func createWidgetPosition(_ view: UIView) -> ButtonPositionSize {
        let position = ButtonPositionSize(id: getViewName(view))
        if view === topBarPanelContainer {
            position.setMoveDescendantsVertical()
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_TOP)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_FULL_WIDTH)
        } else if view is OADownloadMapWidget {
            position.setMoveDescendantsVertical()
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_TOP)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_FULL_WIDTH)
        } else if view === leftWidgetsPanel {
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_TOP)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_LEFT)
            if OAUtilities.isPortrait() {
                position.setMoveDescendantsVertical()
            } else {
                position.setMoveDescendantsHorizontal()
            }
        } else if view === rightWidgetsPanel {
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_TOP)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_RIGHT)
            if OAUtilities.isPortrait() {
                position.setMoveDescendantsVertical()
            } else {
                position.setMoveDescendantsHorizontal()
            }
        } else if view === bottomBarPanelContainer {
            position.setMoveDescendantsVertical()
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_BOTTOM)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_FULL_WIDTH)
        } else if view is OAMapRulerView {
            position.setMoveHorizontal()
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_BOTTOM)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_LEFT)
        } else {
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_TOP)
            position.setPositionHorizontal(posH: ButtonPositionSize.Companion().POS_LEFT)
        }
        
        return updateWidgetPosition(view, position)
    }
    
    private func getViewName(_ view: UIView) -> String {
        (view as? OAHudButton)?.buttonState?.id ?? view.accessibilityIdentifier ?? view.restorationIdentifier ?? String(describing: type(of: view))
    }
    
    private func updatePositionParams(for view: UIView, with position: ButtonPositionSize) {
        updateButtonParams(for: view, with: position)
    }
    
    private func isBottomPanelVisible() -> Bool {
        guard let bottomBarPanelContainer else { return false }
        return !bottomBarPanelContainer.isHidden && bottomBarPanelContainer.alpha > 0.01 && bottomBarPanelContainer.bounds.width > 0 && bottomBarPanelContainer.bounds.height > 0
    }
    
    @discardableResult private func updateWidgetPosition(_ view: UIView, _ position: ButtonPositionSize) -> ButtonPositionSize {
        let cell = CGFloat(ButtonPositionSize.Companion().CELL_SIZE_DP)
        if view is OADownloadMapWidget {
            let insets = containerView.safeAreaInsets
            let fullWidth = max(0, containerView.bounds.width - insets.left - insets.right)
            let heightPx: CGFloat = view.bounds.height > 0 ? view.bounds.height : 155.0
            let width8 = Int32(max(1, floor(fullWidth / dpToPx / cell)))
            let height8 = Int32(max(1, ceil(heightPx / dpToPx / cell)))
            position.setSize(width8dp: width8, height8dp: height8)
            position.marginX = 0
            position.marginY = 0
            return position
        }
        
        let width8 = Int32(max(1, Int(view.bounds.width / dpToPx / cell)))
        let height8 = Int32(max(1, Int(view.bounds.height / dpToPx / cell)))
        position.setSize(width8dp: width8, height8dp: height8)
        if view === leftWidgetsPanel || view === rightWidgetsPanel {
            let insets = containerView.safeAreaInsets
            let parentW = Int(containerView.bounds.width - insets.left - insets.right)
            let parentH = Int(getAdjustedHeight())
            let m = OAUtilities.relativeMargins(for: view, inParent: containerView)
            if m.left >= 0, m.top >= 0, m.right >= 0, m.bottom >= 0 {
                let isRTL = containerView.isDirectionRTL()
                let startInset = isRTL ? insets.right : insets.left
                let endInset = isRTL ? insets.left : insets.right
                let leftAligned = position.isLeft
                let topAligned = position.isTop
                let xRaw = leftAligned ? m.left - startInset : m.right - endInset
                let yRaw = topAligned ? m.top - statusBarHeight : m.bottom - insets.bottom
                let xPixels = Int(round(max(0, xRaw)))
                let yPixels = Int(round(max(0, yRaw)))
                position.calcGridPositionFromPixel(dpToPix: Float(dpToPx), widthPx: Int32(parentW), heightPx: Int32(parentH), gravLeft: leftAligned, x: Int32(xPixels), gravTop: topAligned, y: Int32(yPixels))
            }
        } else if view is OAMapRulerView {
            position.marginX = 0
            position.marginY = 0
        }
        
        return position
    }
    
    @discardableResult private func updateButtonParams(for view: UIView, with position: ButtonPositionSize) -> Bool {
        if view is OADownloadMapWidget {
            let insets = containerView.safeAreaInsets
            let hostW = containerView.bounds.width
            let available = max(0, hostW - insets.left - insets.right)
            let isPortrait = OAUtilities.isPortrait()
            let desiredWidth = isPortrait ? available : min(available, hostW * 0.5)
            let x = insets.left + (available - desiredWidth) / 2.0
            let y = statusBarHeight
            let height = view.bounds.height > 0 ? view.bounds.height : 155.0
            let newFrame = CGRect(x: x, y: y, width: desiredWidth, height: height)
            if view.frame != newFrame {
                view.frame = newFrame
                return true
            }
            
            return false
        }
        
        let cellFixPx: CGFloat = max(0, (hudBasePaddingDp - CGFloat(ButtonPositionSize.Companion().DEF_MARGIN_DP)) * dpToPx)
        let startX = CGFloat(position.getXStartPix(dpToPix: Float(dpToPx))) + cellFixPx
        let startY = CGFloat(position.getYStartPix(dpToPix: Float(dpToPx))) + cellFixPx
        let insets = containerView.safeAreaInsets
        let placeOnLeft = containerView.isDirectionRTL() ? !position.isLeft : position.isLeft
        let extraTop = position.isTop ? externalTopOverlayPx : 0.0
        let extraBottom = position.isBottom ? externalBottomOverlayPx : 0.0
        let newX: CGFloat = placeOnLeft ? insets.left + startX : containerView.bounds.width - insets.right - view.bounds.width - startX
        let newY: CGFloat = position.isTop ? statusBarHeight + startY + extraTop : statusBarHeight + getAdjustedHeight() - view.bounds.height - startY - extraBottom
        let newOrigin = CGPoint(x: newX, y: newY)
        if view.frame.origin != newOrigin {
            view.frame.origin = newOrigin
            return true
        }
        
        return false
    }
    
    func configure(leftWidgetsPanel: UIView?, rightWidgetsPanel: UIView?, topBarPanelContainer: UIView?, bottomBarPanelContainer: UIView?) {
        self.leftWidgetsPanel = leftWidgetsPanel
        self.rightWidgetsPanel = rightWidgetsPanel
        self.topBarPanelContainer = topBarPanelContainer
        self.bottomBarPanelContainer = bottomBarPanelContainer
        containerView.layoutIfNeeded()
        widgetPositions.removeAll()
        widgetOrder.removeAll()
        [topBarPanelContainer, leftWidgetsPanel, rightWidgetsPanel, bottomBarPanelContainer].forEach { addPosition($0) }
        updateVerticalPanels()
    }
    
    func addMapButton(_ button: OAHudButton) {
        if button.superview !== containerView {
            containerView.addSubview(button)
        }
        
        if button.bounds.size == .zero {
            button.sizeToFit()
        }
        
        button.buttonState?.updatePositions()
        let position = button.buttonState?.getDefaultPositionSize() ?? ButtonPositionSize(id: getViewName(button))
        updateButtonParams(for: button, with: position)
        mapButtons.append(button)
        refresh()
    }
    
    func addWidget(_ view: UIView) {
        if view.superview !== containerView {
            containerView.addSubview(view)
        }
        
        if view.bounds.size == .zero {
            view.sizeToFit()
        }
        
        let position = createWidgetPosition(view)
        updateButtonParams(for: view, with: position)
        additionalWidgetPositions[view] = position
        if !additionalOrder.contains(view) {
            additionalOrder.append(view)
        }
        
        refresh()
    }
    
    func removeWidget(_ view: UIView) {
        additionalWidgetPositions.removeValue(forKey: view)
        if let i = additionalOrder.firstIndex(of: view) {
            additionalOrder.remove(at: i)
        }
        
        refresh()
    }
    
    func removeMapButton(_ button: OAHudButton) {
        button.removeFromSuperview()
        if let idx = mapButtons.firstIndex(of: button) {
            mapButtons.remove(at: idx)
        }
        
        refresh()
    }
    
    func setExternalTopOverlay(_ pixels: CGFloat, ignorePanels: Bool) {
        let px = max(0, pixels)
        var changed = false
        if abs(px - externalTopOverlayPx) > 0.0 {
            externalTopOverlayPx = px
            changed = true
        }
        
        if ignoreTopSidePanels != ignorePanels {
            ignoreTopSidePanels = ignorePanels
            changed = true
        }
        
        if changed {
            refresh()
        }
    }
    
    func setExternalBottomOverlay(_ pixels: CGFloat, ignorePanels: Bool) {
        let px = max(0, pixels)
        var changed = false
        if abs(px - externalBottomOverlayPx) > 0.0 {
            externalBottomOverlayPx = px
            changed = true
        }
        
        if ignoreBottomSidePanels != ignorePanels {
            ignoreBottomSidePanels = ignorePanels
            changed = true
        }
        
        if changed {
            refresh()
        }
    }
    
    func updateButtons() {
        guard containerView.bounds.width > 0 || containerView.bounds.height > 0 || !containerView.isHidden else { return }
        let positionMap = getButtonPositionSizes()
        for (view, pos) in positionMap {
            if view is OAHudButton || view is OAMapRulerView || view is OADownloadMapWidget {
                updatePositionParams(for: view, with: pos)
            }
        }
    }
    
    func collectPositions() -> [UIView: ButtonPositionSize] {
        var map: [UIView: ButtonPositionSize] = [:]
        for (view, _) in widgetPositions where !view.isHidden {
            let pos = createWidgetPosition(view)
            if pos.width > 0 && pos.height > 0 {
                map[view] = pos
            }
        }
        
        for btn in mapButtons where !btn.isHidden {
            if let pos = btn.buttonState?.getDefaultPositionSize(),
               pos.width > 0, pos.height > 0 {
                map[btn] = pos
            }
        }
        
        var updatedAdditional: [UIView: ButtonPositionSize] = additionalWidgetPositions
        for (view, saved) in additionalWidgetPositions where !view.isHidden {
            let pos = updateWidgetPosition(view, saved)
            if pos.width > 0 && pos.height > 0 {
                map[view] = pos
                updatedAdditional[view] = pos
            } else {
                updatedAdditional.removeValue(forKey: view)
            }
        }
        
        additionalWidgetPositions = updatedAdditional
        return map
    }
    
    private func collectPositionsOrdered() -> [(UIView, ButtonPositionSize)] {
        var result: [(UIView, ButtonPositionSize)] = []
        var updatedAdditional = additionalWidgetPositions
        var hasBanner = false
        if let banner = additionalOrder.first(where: { !$0.isHidden && ($0 is OADownloadMapWidget) }) {
            let pos: ButtonPositionSize
            if let saved = additionalWidgetPositions[banner] {
                pos = updateWidgetPosition(banner, saved)
            } else {
                pos = createWidgetPosition(banner)
            }
            
            if pos.width > 0 && pos.height > 0 {
                result.append((banner, pos))
                updatedAdditional[banner] = pos
                hasBanner = true
            } else {
                updatedAdditional.removeValue(forKey: banner)
            }
        }
        
        var pendingSidePanels: [(UIView, ButtonPositionSize)] = []
        for v in widgetOrder where !v.isHidden {
            let pos = createWidgetPosition(v)
            if pos.width > 0 && pos.height > 0 {
                if hasBanner && (v === leftWidgetsPanel || v === rightWidgetsPanel) {
                    pendingSidePanels.append((v, pos))
                } else {
                    result.append((v, pos))
                }
            }
        }
        
        var posById: [String: ButtonPositionSize] = [:]
        for btn in mapButtons where !btn.isHidden {
            guard let state = btn.buttonState else { continue }
            let defPosition = state.getDefaultPositionSize()
            guard defPosition.width > 0 && defPosition.height > 0 else { continue }
            posById[state.id] = defPosition
        }
        
        var rightX: Int32 = 0
        var leftX: Int32 = 0
        var applyFix = false
        if !ignoreBottomSidePanels, isBottomPanelVisible(), let baseZoom = posById[ZoomInButtonState.hudId] ?? posById[ZoomOutButtonState.hudId], let ml = posById[MyLocationButtonState.hudId], let m3 = posById[Map3DButtonState.map3DHudId], ml.posH == ButtonPositionSize.Companion().POS_RIGHT, ml.posV == ButtonPositionSize.Companion().POS_BOTTOM, ml.marginX == baseZoom.marginX, m3.posH == ButtonPositionSize.Companion().POS_RIGHT, m3.posV == ButtonPositionSize.Companion().POS_BOTTOM, m3.marginX == baseZoom.marginX {
            rightX = baseZoom.marginX
            leftX = rightX + baseZoom.width + 1
            applyFix = true
        }
        
        for btn in mapButtons where !btn.isHidden {
            guard let state = btn.buttonState, let p = posById[state.id] else { continue }
            if applyFix {
                switch state.id {
                case ZoomInButtonState.hudId, ZoomOutButtonState.hudId:
                    p.marginX = rightX; p.xMove = false; p.yMove = true
                case MyLocationButtonState.hudId, Map3DButtonState.map3DHudId:
                    p.marginX = leftX;  p.xMove = false; p.yMove = true
                default: break
                }
            }
            
            result.append((btn, p))
        }
        
        if hasBanner {
            result.append(contentsOf: pendingSidePanels)
        }
        
        for v in additionalOrder where !v.isHidden && !(v is OADownloadMapWidget) {
            if let saved = additionalWidgetPositions[v] {
                let pos = updateWidgetPosition(v, saved)
                if pos.width > 0 && pos.height > 0 {
                    result.append((v, pos))
                    updatedAdditional[v] = pos
                } else {
                    updatedAdditional.removeValue(forKey: v)
                }
            }
        }
        
        additionalWidgetPositions = updatedAdditional
        return result
    }
    
    func updateButton(_ button: OAHudButton, save: Bool) {
        guard let state = button.buttonState else {
            if save {
                button.savePosition()
            }
            
            refresh()
            return
        }
        
        let pos = state.getPositionSize()
        let insets = containerView.safeAreaInsets
        let width = Int(containerView.bounds.width - insets.left - insets.right)
        let height = Int(getAdjustedHeight())
        let m = OAUtilities.relativeMargins(for: button, inParent: containerView)
        let isRTL = containerView.isDirectionRTL()
        let startInset = isRTL ? insets.right : insets.left
        let endInset = isRTL ? insets.left : insets.right
        let leftAligned = pos.isLeft
        let topAligned = pos.isTop
        let xRaw = leftAligned ? m.left - startInset : m.right - endInset
        let yRaw = topAligned ? m.top - statusBarHeight : m.bottom - insets.bottom
        let xPixels = Int(round(max(0, xRaw)))
        let yPixels = Int(round(max(0, yRaw)))
        pos.calcGridPositionFromPixel(dpToPix: Float(dpToPx), widthPx: Int32(width), heightPx: Int32(height), gravLeft: leftAligned, x: Int32(xPixels), gravTop: topAligned, y: Int32(yPixels))
        state.getPositionSize().fromLongValue(v: pos.toLongValue())
        updatePositionParams(for: button, with: pos)
        if save {
            button.savePosition()
        }
        
        refresh()
    }
    
    func getAdjustedHeight() -> CGFloat {
        containerView.bounds.height - statusBarHeight - containerView.safeAreaInsets.bottom
    }
    
    func onContainerSizeChanged() {
        portrait = OAUtilities.isPortrait()
        statusBarHeight = OAUtilities.getStatusBarHeight()
        for b in mapButtons {
            b.buttonState?.updatePositions()
        }
        
        let w = containerView.bounds.width
        if w > 0, abs(w - lastWidth) > 0.1 {
            lastWidth = w
            updateVerticalPanels()
        } else {
            updateButtons()
        }
    }
    
    func updateVerticalPanels() {
        containerView.layoutIfNeeded()
        refresh()
    }
    
    func viewDidChangeLayout(_ view: UIView) {
        if let pos = widgetPositions[view] {
            let newPos = updateWidgetPosition(view, pos)
            widgetPositions[view] = newPos
        }
        
        if view === leftWidgetsPanel || view === rightWidgetsPanel {
            updateVerticalPanels()
            return
        }
        
        refresh()
    }
}
