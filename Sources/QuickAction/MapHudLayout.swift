//
//  MapHudLayout.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol MapHudLayoutInput: AnyObject {
    func viewDidChangeLayout(_ view: UIView)
    func viewDidChangeVisibility(_ view: UIView)
    func registerObservedView(_ view: UIView)
}

@objc protocol SideWidgetsPanelProtocol {
    var isRightSide: Bool { get }
}

@objc protocol VerticalWidgetPanelProtocol {
    var isTopPanel: Bool { get }
}

@objc protocol UIViewMarginUpdatable {
    var leftMargin: CGFloat { get set }
    var rightMargin: CGFloat { get set }
    var bottomMargin: CGFloat { get set }
}

@objc protocol RulerWidgetProtocol {}

@objcMembers
final class MapHudLayout: NSObject {
    private static let uiRefreshInterval: TimeInterval = 0.1
    private static let topBarMaxWidthPercentage: CGFloat = 0.6
    
    private let containerView: UIView
    private let dpToPx: CGFloat = 1.0
    private let tablet: Bool
    
    private var statusBarHeight: CGFloat
    private var panelsMargin: CGFloat
    private var portrait: Bool
    private var lastWidth: CGFloat = 0
    private var mapButtons: [OAHudButton] = []
    private var widgetPositions: [UIView: ButtonPositionSize] = [:]
    private var additionalWidgetPositions: [UIView: ButtonPositionSize] = [:]
    private var widgetOrder: [UIView] = []
    private var additionalOrder: [UIView] = []
    private var updateButtonsWorkItem: DispatchWorkItem?
    private var updateVerticalPanelsWorkItem: DispatchWorkItem?
    private var updateAlarmsWorkItem: DispatchWorkItem?
    
    private weak var alarmsContainer: UIView?
    private weak var topBarPanelContainer: UIView?
    private weak var leftWidgetsPanel: UIView?
    private weak var rightWidgetsPanel: UIView?
    private weak var bottomWidgetsPanel: UIView?
    
    init(containerView: UIView) {
        self.containerView = containerView
        self.tablet = OAUtilities.isIPad()
        self.portrait = OAUtilities.isPortrait()
        self.panelsMargin = 16
        self.statusBarHeight = OAUtilities.getStatusBarHeight()
        super.init()
    }
    
    deinit {
        updateButtonsWorkItem?.cancel()
        updateButtonsWorkItem = nil
        updateVerticalPanelsWorkItem?.cancel()
        updateVerticalPanelsWorkItem = nil
        updateAlarmsWorkItem?.cancel()
        updateAlarmsWorkItem = nil
    }
    
    private func addPosition(_ view: UIView?, callback: (() -> Void)? = nil) {
        guard let view else { return }
        widgetPositions[view] = createWidgetPosition(view)
        if !widgetOrder.contains(view) {
            widgetOrder.append(view)
        }
    }
    
    private func refresh() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
            
            return
        }
        
        updateButtonsWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.updateButtons()
        }
        
        updateButtonsWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.uiRefreshInterval, execute: work)
    }
    
    private func getButtonPositionSizes() -> [UIView: ButtonPositionSize] {
        let pairs = collectPositionsOrdered()
        let gridW = Int(round(containerView.bounds.width / dpToPx / CGFloat(ButtonPositionSize.Companion().CELL_SIZE_DP)))
        let gridH = Int(round(getAdjustedHeight() / dpToPx / CGFloat(ButtonPositionSize.Companion().CELL_SIZE_DP)))
        ButtonPositionSize.Companion().computeNonOverlap(space: 1, buttons: pairs.map { $0.1 }, totalWidth: Int32(gridW), totalHeight: Int32(gridH))
        var map: [UIView: ButtonPositionSize] = [:]
        for (v, p) in pairs {
            map[v] = p
        }
        
        return map
    }
    
    private func createWidgetPosition(_ view: UIView) -> ButtonPositionSize {
        let position = ButtonPositionSize(id: getViewName(view))
        if let vertical = view as? VerticalWidgetPanelProtocol {
            position.setMoveDescendantsVertical()
            position.setPositionVertical(posV: vertical.isTopPanel ? ButtonPositionSize.Companion().POS_TOP : ButtonPositionSize.Companion().POS_BOTTOM)
            position.setPositionHorizontal(posH: shouldCenterVerticalPanels() ? ButtonPositionSize.Companion().POS_LEFT : ButtonPositionSize.Companion().POS_FULL_WIDTH)
        } else if let side = view as? SideWidgetsPanelProtocol {
            position.setMoveDescendantsVertical()
            position.setPositionVertical(posV: ButtonPositionSize.Companion().POS_TOP)
            position.setPositionHorizontal(posH: side.isRightSide ? ButtonPositionSize.Companion().POS_RIGHT : ButtonPositionSize.Companion().POS_LEFT)
        } else if view is RulerWidgetProtocol {
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
        view.accessibilityIdentifier ?? view.restorationIdentifier ?? String(describing: type(of: view))
    }
    
    @discardableResult private func updateWidgetPosition(_ view: UIView, _ position: ButtonPositionSize) -> ButtonPositionSize {
        let cell = CGFloat(ButtonPositionSize.Companion().CELL_SIZE_DP)
        let width8 = Int32(round(view.bounds.width / dpToPx / cell))
        let height8 = Int32(round(view.bounds.height / dpToPx / cell))
        position.setSize(width8dp: width8, height8dp: height8)
        if view is SideWidgetsPanelProtocol || (view is VerticalWidgetPanelProtocol && shouldCenterVerticalPanels()) {
            let parentW = Int(containerView.bounds.width)
            let parentH = Int(getAdjustedHeight())
            let m = getRelativeMargins(in: containerView, for: view)
            if m.left >= 0, m.top >= 0, m.right >= 0, m.bottom >= 0 {
                let topAligned = position.isTop
                let leftAligned = position.isLeft
                let xPixels = Int(round(leftAligned ? m.left : m.right))
                let yRaw = topAligned ? m.top - statusBarHeight : m.bottom - statusBarHeight
                let yPixels = Int(round(yRaw))
                position.calcGridPositionFromPixel(dpToPix: Float(dpToPx), widthPx: Int32(parentW), heightPx: Int32(parentH), gravLeft: leftAligned, x: Int32(xPixels), gravTop: topAligned, y: Int32(yPixels))
            }
        } else if view is RulerWidgetProtocol {
            position.marginX = 0
            position.marginY = 0
        }
        
        return position
    }
    
    @discardableResult private func updateButtonParams(for view: UIView, with position: ButtonPositionSize) -> Bool {
        let baseOffsetDp: CGFloat = 16.0
        let defMarginDp: CGFloat = CGFloat(ButtonPositionSize.Companion().DEF_MARGIN_DP)
        let cellFixPx: CGFloat = max(0, (baseOffsetDp - defMarginDp) * dpToPx)
        let startX = CGFloat(position.getXStartPix(dpToPix: Float(dpToPx))) + cellFixPx
        let startY = CGFloat(position.getYStartPix(dpToPix: Float(dpToPx))) + cellFixPx
        let insets = containerView.safeAreaInsets
        let containerW = containerView.bounds.width
        let containerH = getAdjustedHeight()
        let newX: CGFloat = position.isLeft ? insets.left + startX : containerW - insets.right - view.bounds.width - startX
        let newY: CGFloat = position.isTop ? statusBarHeight + startY : statusBarHeight + containerH - view.bounds.height - startY
        let newOrigin = CGPoint(x: newX, y: newY)
        if view.frame.origin != newOrigin {
            view.frame.origin = newOrigin
            return true
        }
        
        return false
    }
    
    private func updatePositionParams(for view: UIView, with position: ButtonPositionSize) {
        updateButtonParams(for: view, with: position)
    }
    
    private func updateHorizontalMargins(target: UIView, leftPanel: UIView, rightPanel: UIView) {
        let safeInsets = containerView.safeAreaInsets
        let totalWidth = containerView.bounds.width - safeInsets.left - safeInsets.right
        guard totalWidth > 0 else { return }
        var newLeftMargin: CGFloat = 0
        var newRightMargin: CGFloat = 0
        if shouldCenterVerticalPanels() {
            let defaultWidth = totalWidth * Self.topBarMaxWidthPercentage
            let defaultMargin = (totalWidth - defaultWidth) / 2.0
            let leftWidth = leftPanel.isHidden ? 0 : leftPanel.bounds.width
            let rightWidth = rightPanel.isHidden ? 0 : rightPanel.bounds.width
            newLeftMargin = max(defaultMargin, leftWidth > 0 ? leftWidth + panelsMargin : 0)
            newRightMargin = max(defaultMargin, rightWidth > 0 ? rightWidth + panelsMargin : 0)
        }
        
        if let updatable = target as? UIViewMarginUpdatable {
            if updatable.leftMargin != newLeftMargin || updatable.rightMargin != newRightMargin {
                updatable.leftMargin = newLeftMargin
                updatable.rightMargin = newRightMargin
            }
        }
        
        if target.translatesAutoresizingMaskIntoConstraints {
            let x = safeInsets.left + newLeftMargin
            let width = totalWidth - newLeftMargin - newRightMargin
            if target.frame.origin.x != x || abs(target.frame.width - width) > .ulpOfOne {
                target.frame.origin.x = x
                target.frame.size.width = width
            }
        }
    }
    
    private func getRelativeMargins(in container: UIView, for subview: UIView) -> (left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) {
        container.layoutIfNeeded()
        let frameInContainer = subview.convert(subview.bounds, to: container)
        let left = frameInContainer.minX
        let top = frameInContainer.minY
        let right = container.bounds.width - frameInContainer.maxX
        let bottom = container.bounds.height - frameInContainer.maxY
        return (left, top, right, bottom)
    }
    
    func configure(alarmsContainer: UIView?, leftWidgetsPanel: UIView?, rightWidgetsPanel: UIView?, topBarPanelContainer: UIView?, bottomWidgetsPanel: UIView?, userPanelsMargin: NSNumber?) {
        self.alarmsContainer = alarmsContainer
        self.leftWidgetsPanel = leftWidgetsPanel
        self.rightWidgetsPanel = rightWidgetsPanel
        self.topBarPanelContainer = topBarPanelContainer
        self.bottomWidgetsPanel = bottomWidgetsPanel
        if let userPanelsMargin {
            self.panelsMargin = CGFloat(truncating: userPanelsMargin)
        }
        
        containerView.layoutIfNeeded()
        widgetPositions.removeAll()
        widgetOrder.removeAll()
        addPosition(topBarPanelContainer)
        addPosition(leftWidgetsPanel)
        addPosition(rightWidgetsPanel)
        addPosition(bottomWidgetsPanel)
        updateVerticalPanels()
        updateAlarmsContainer()
        refresh()
    }
    
    func addMapButton(_ button: OAHudButton) {
        DispatchQueue.main.async {
            if button.superview !== self.containerView {
                self.containerView.addSubview(button)
            }
            
            if button.bounds.size == .zero {
                button.sizeToFit()
            }
            
            button.buttonState?.updatePositions()
            let position = button.buttonState?.getDefaultPositionSize() ?? ButtonPositionSize(id: self.getViewName(button))
            self.updateButtonParams(for: button, with: position)
            self.mapButtons.append(button)
            self.refresh()
        }
    }
    
    func addWidget(_ view: UIView) {
        DispatchQueue.main.async {
            self.containerView.addSubview(view)
            if view.bounds.size == .zero {
                view.sizeToFit()
            }
            
            let position = self.createWidgetPosition(view)
            self.updateButtonParams(for: view, with: position)
            self.additionalWidgetPositions[view] = position
            if !self.additionalOrder.contains(view) {
                self.additionalOrder.append(view)
            }
            
            self.refresh()
        }
    }
    
    func removeWidget(_ view: UIView) {
        DispatchQueue.main.async {
            self.additionalWidgetPositions.removeValue(forKey: view)
            if let i = self.additionalOrder.firstIndex(of: view) {
                self.additionalOrder.remove(at: i)
            }
            
            self.refresh()
        }
    }
    
    func removeMapButton(_ button: OAHudButton) {
        DispatchQueue.main.async {
            if let idx = self.mapButtons.firstIndex(of: button) {
                self.mapButtons.remove(at: idx)
            }
            
            button.removeFromSuperview()
            self.refresh()
        }
    }
    
    func updateButtons() {
        if containerView.bounds.width <= 0 && containerView.bounds.height <= 0 && containerView.isHidden {
            return
        }
        
        let positionMap = getButtonPositionSizes()
        for (view, pos) in positionMap {
            if view is OAHudButton || view is RulerWidgetProtocol {
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
        for v in widgetOrder where !v.isHidden {
            let pos = createWidgetPosition(v)
            if pos.width > 0 && pos.height > 0 {
                result.append((v, pos))
            }
        }
        
        for btn in mapButtons where !btn.isHidden {
            if let pos = btn.buttonState?.getDefaultPositionSize(), pos.width > 0, pos.height > 0 {
                result.append((btn, pos))
            }
        }
        
        var updatedAdditional = additionalWidgetPositions
        for v in additionalOrder where !v.isHidden {
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
        DispatchQueue.main.async {
            guard let state = button.buttonState else {
                if save {
                    button.savePosition()
                }
                
                self.refresh()
                return
            }
            
            let pos = state.getPositionSize()
            let insets = self.containerView.safeAreaInsets
            let width = Int(self.containerView.bounds.width - insets.left - insets.right)
            let height = Int(self.getAdjustedHeight())
            let m = self.getRelativeMargins(in: self.containerView, for: button)
            let leftAligned = pos.isLeft
            let topAligned = pos.isTop
            let xRaw = leftAligned ? (m.left - insets.left) : (m.right - insets.right)
            let yRaw = topAligned ? (m.top - self.statusBarHeight) : (m.bottom - insets.bottom)
            let xPixels = Int(round(max(0, xRaw)))
            let yPixels = Int(round(max(0, yRaw)))
            pos.calcGridPositionFromPixel(dpToPix: Float(self.dpToPx), widthPx: Int32(width), heightPx: Int32(height), gravLeft: leftAligned, x: Int32(xPixels), gravTop: topAligned, y: Int32(yPixels))
            state.getPositionSize().fromLongValue(v: pos.toLongValue())
            self.updatePositionParams(for: button, with: pos)
            if save {
                button.savePosition()
            }
            
            self.refresh()
        }
    }
    
    func getAdjustedHeight() -> CGFloat {
        containerView.bounds.height - statusBarHeight - containerView.safeAreaInsets.bottom
    }
    
    func shouldCenterVerticalPanels() -> Bool {
        !portrait || tablet
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
            if shouldCenterVerticalPanels() {
                updateAlarmsContainer()
            }
        }
        
        updateButtons()
    }
    
    func updateVerticalPanels() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.updateVerticalPanels()
            }
            
            return
        }
        
        updateVerticalPanelsWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let left = self.leftWidgetsPanel, let right = self.rightWidgetsPanel, self.containerView.bounds.width > 0 else { return }
            if let top = self.topBarPanelContainer {
                self.updateHorizontalMargins(target: top, leftPanel: left, rightPanel: right)
            }
            
            if let bottom = self.bottomWidgetsPanel {
                self.updateHorizontalMargins(target: bottom, leftPanel: left, rightPanel: right)
            }
        }
        
        updateVerticalPanelsWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.uiRefreshInterval, execute: work)
    }
    
    func updateAlarmsContainer() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.updateAlarmsContainer()
            }
            
            return
        }
        
        updateAlarmsWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, let alarms = self.alarmsContainer else { return }
            self.containerView.layoutIfNeeded()
            let baseMargin: CGFloat = 20.0
            var panelOffset: CGFloat = 0.0
            if self.shouldCenterVerticalPanels(), let bottomPanel = self.bottomWidgetsPanel, !bottomPanel.isHidden {
                panelOffset = bottomPanel.bounds.height
            }
            
            let bottomMargin = max(baseMargin, panelOffset) + self.containerView.safeAreaInsets.bottom
            if let updatable = alarms as? UIViewMarginUpdatable {
                if updatable.bottomMargin != bottomMargin {
                    updatable.bottomMargin = bottomMargin
                }
            }
            
            if alarms.translatesAutoresizingMaskIntoConstraints {
                let newY = self.containerView.bounds.height - bottomMargin - alarms.bounds.height
                if abs(alarms.frame.origin.y - newY) > .ulpOfOne {
                    alarms.frame.origin.y = newY
                }
            }
        }
        
        updateAlarmsWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.uiRefreshInterval, execute: work)
    }
}

extension MapHudLayout: MapHudLayoutInput {
    func registerObservedView(_ view: UIView) {
        addPosition(view)
        refresh()
    }
    
    func viewDidChangeLayout(_ view: UIView) {
        if let pos = widgetPositions[view] {
            let newPos = updateWidgetPosition(view, pos)
            widgetPositions[view] = newPos
        }
        
        if view === leftWidgetsPanel || view === rightWidgetsPanel {
            updateVerticalPanels()
        }
        if view === bottomWidgetsPanel {
            updateAlarmsContainer()
        }
        
        refresh()
    }
    
    func viewDidChangeVisibility(_ view: UIView) {
        if view === leftWidgetsPanel || view === rightWidgetsPanel {
            updateVerticalPanels()
        }
        
        if view === bottomWidgetsPanel {
            updateAlarmsContainer()
        }
        
        refresh()
    }
}
