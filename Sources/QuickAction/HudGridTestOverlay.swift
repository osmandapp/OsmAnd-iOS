//
//  HudGridTestOverlay.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 27.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class HudGridTestOverlay: UIView {
    
    struct Config: Equatable {
        var cellSizePx: CGFloat = CGFloat(ButtonPositionSize.companion.CELL_SIZE_DP)
        var defaultMarginPx: CGFloat = CGFloat(ButtonPositionSize.companion.DEF_MARGIN_DP)
        var cellFixPx: CGFloat = 0
        var statusBarHeight: CGFloat = 0
        var safeAreaInsets: UIEdgeInsets = .zero
        var bottomOverlayPx: CGFloat = 0
        var showsEffectiveGrid: Bool = false
        var showsSlots: Bool = false
        var showsFrames: Bool = false
    }
    
    struct Item {
        let view: UIView
        let position: ButtonPositionSize
        let dpToPx: CGFloat
    }
    
    var cfg = Config() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var items: [Item] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        contentMode = .redraw
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let physical = UIEdgeInsets(top: cfg.statusBarHeight, left: cfg.safeAreaInsets.left, bottom: cfg.safeAreaInsets.bottom, right: cfg.safeAreaInsets.right)
        if cfg.showsEffectiveGrid {
            drawFourCornerGridColored(in: ctx)
        }
        
        guard cfg.showsSlots || cfg.showsFrames else { return }
        for item in items {
            let slot = makeSlotRect(item: item, physical: physical, cellFix: cfg.cellFixPx)
            if cfg.showsSlots {
                drawFilledRect(in: ctx, rect: slot, fill: UIColor.systemTeal.withAlphaComponent(0.25), stroke: UIColor.systemTeal)
            }
            
            if cfg.showsFrames {
                let frame = item.view.frame
                let snapped = CGRect(x: snapToPixel(frame.minX), y: snapToPixel(frame.minY), width: max(0, snapToPixel(frame.maxX) - snapToPixel(frame.minX)), height: max(0, snapToPixel(frame.maxY) - snapToPixel(frame.minY)))
                strokeRect(in: ctx, rect: snapped, stroke: .systemRed)
            }
        }
    }
    
    private func drawFourCornerGridColored(in ctx: CGContext) {
        let cell = cfg.cellSizePx
        guard cell > 0 else { return }
        let left0 = cfg.safeAreaInsets.left + cfg.cellFixPx + cfg.defaultMarginPx
        let right0 = bounds.width - cfg.safeAreaInsets.right - cfg.cellFixPx - cfg.defaultMarginPx
        let top0 = cfg.statusBarHeight + cfg.cellFixPx + cfg.defaultMarginPx
        let bottom0 = bounds.height - cfg.safeAreaInsets.bottom - cfg.cellFixPx - cfg.defaultMarginPx - cfg.bottomOverlayPx
        guard left0 < right0, top0 < bottom0 else { return }
        let midX = snapToPixel((left0 + right0) / 2)
        let midY = snapToPixel((top0 + bottom0) / 2)
        
        func drawCorner(clip: CGRect, startX: CGFloat, stepX: CGFloat, startY: CGFloat, stepY: CGFloat, color: UIColor) {
            guard clip.width > 0, clip.height > 0 else { return }
            ctx.saveGState()
            ctx.addRect(clip)
            ctx.clip()
            color.setStroke()
            ctx.setLineWidth(1)
            ctx.setShouldAntialias(false)
            
            var x = startX
            if stepX > 0 {
                while x <= clip.maxX {
                    let sx = snapToPixel(x)
                    ctx.move(to: CGPoint(x: sx, y: clip.minY))
                    ctx.addLine(to: CGPoint(x: sx, y: clip.maxY))
                    x += stepX
                }
            } else {
                while x >= clip.minX {
                    let sx = snapToPixel(x)
                    ctx.move(to: CGPoint(x: sx, y: clip.minY))
                    ctx.addLine(to: CGPoint(x: sx, y: clip.maxY))
                    x += stepX
                }
            }
            
            var y = startY
            if stepY > 0 {
                while y <= clip.maxY {
                    let sy = snapToPixel(y)
                    ctx.move(to: CGPoint(x: clip.minX, y: sy))
                    ctx.addLine(to: CGPoint(x: clip.maxX, y: sy))
                    y += stepY
                }
            } else {
                while y >= clip.minY {
                    let sy = snapToPixel(y)
                    ctx.move(to: CGPoint(x: clip.minX, y: sy))
                    ctx.addLine(to: CGPoint(x: clip.maxX, y: sy))
                    y += stepY
                }
            }
            
            ctx.strokePath()
            ctx.restoreGState()
        }
        
        let topLeftRect = CGRect(x: left0, y: top0, width: max(0, midX - left0), height: max(0, midY - top0))
        let topRightRect = CGRect(x: midX, y: top0, width: max(0, right0 - midX), height: max(0, midY - top0))
        let bottomLeftRect = CGRect(x: left0, y: midY, width: max(0, midX - left0), height: max(0, bottom0 - midY))
        let bottomRightRect = CGRect(x: midX, y: midY, width: max(0, right0 - midX), height: max(0, bottom0 - midY))
        drawCorner(clip: topLeftRect, startX: left0, stepX: cell, startY: top0, stepY: cell, color: UIColor.systemOrange.withAlphaComponent(0.9))
        drawCorner(clip: topRightRect, startX: right0, stepX: -cell, startY: top0, stepY: cell, color: UIColor.systemGreen.withAlphaComponent(0.9))
        drawCorner(clip: bottomLeftRect, startX: left0, stepX: cell, startY: bottom0, stepY: -cell, color: UIColor.systemPurple.withAlphaComponent(0.9))
        drawCorner(clip: bottomRightRect, startX: right0, stepX: -cell, startY: bottom0, stepY: -cell, color: UIColor.systemYellow.withAlphaComponent(0.9))
        ctx.saveGState()
        UIColor.systemRed.withAlphaComponent(0.9).setStroke()
        ctx.setLineWidth(1)
        ctx.setShouldAntialias(false)
        ctx.move(to: CGPoint(x: midX, y: snapToPixel(top0)))
        ctx.addLine(to: CGPoint(x: midX, y: snapToPixel(bottom0)))
        ctx.move(to: CGPoint(x: snapToPixel(left0), y: midY))
        ctx.addLine(to: CGPoint(x: snapToPixel(right0), y: midY))
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    private func makeSlotRect(item: Item, physical: UIEdgeInsets, cellFix: CGFloat) -> CGRect {
        let cell = CGFloat(ButtonPositionSize.companion.CELL_SIZE_DP) * item.dpToPx
        let def = CGFloat(ButtonPositionSize.companion.DEF_MARGIN_DP) * item.dpToPx
        let startX = (CGFloat(item.position.marginX) * cell + def)
        let endX = (CGFloat(item.position.marginX + item.position.width) * cell + def)
        let startY = (CGFloat(item.position.marginY) * cell + def)
        let endY = (CGFloat(item.position.marginY + item.position.height) * cell + def)
        let leftEdge = item.position.isLeft ? physical.left + cellFix + startX : bounds.width - physical.right - cellFix - endX
        let rightEdge = item.position.isLeft ? physical.left + cellFix + endX : bounds.width - physical.right - cellFix - startX
        let topEdge = item.position.isTop ? physical.top + cellFix + startY : bounds.height - physical.bottom - cellFix - endY
        let bottomEdge = item.position.isTop ? physical.top + cellFix + endY : bounds.height - physical.bottom - cellFix - startY
        let xA = snapToPixel(min(leftEdge, rightEdge))
        let xB = snapToPixel(max(leftEdge, rightEdge))
        let yA = snapToPixel(min(topEdge, bottomEdge))
        let yB = snapToPixel(max(topEdge, bottomEdge))
        return CGRect(x: xA, y: yA, width: max(0, xB - xA), height: max(0, yB - yA))
    }
    
    private func drawFilledRect(in ctx: CGContext, rect: CGRect, fill: UIColor, stroke: UIColor) {
        guard rect.width > 0, rect.height > 0 else { return }
        ctx.saveGState()
        fill.setFill()
        stroke.setStroke()
        ctx.setLineWidth(1)
        ctx.setShouldAntialias(false)
        ctx.addRect(rect)
        ctx.drawPath(using: .fillStroke)
        ctx.restoreGState()
    }
    
    private func strokeRect(in ctx: CGContext, rect: CGRect, stroke: UIColor) {
        guard rect.width > 0, rect.height > 0 else { return }
        ctx.saveGState()
        stroke.setStroke()
        ctx.setLineWidth(1)
        ctx.setShouldAntialias(false)
        ctx.addRect(rect)
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    private func snapToPixel(_ value: CGFloat) -> CGFloat {
        let scale = contentScaleFactor > 0 ? contentScaleFactor : UIScreen.main.scale
        return (floor(value * scale) + 0.5) / scale
    }
}
