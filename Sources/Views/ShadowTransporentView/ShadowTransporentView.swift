//
//  ShadowTransporentView.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 08.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objcMembers
class ShadowTransporentView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        guard !bounds.isEmpty else {
            return
        }
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 0, dy: 0),
            cornerRadius: 4)
        let hole = UIBezierPath(
            roundedRect: bounds.insetBy(dx: 1, dy: 1),
            cornerRadius: 4)
            .reversing()
        path.append(hole)
        layer.shadowPath = path.cgPath
    }
}

@objc(OAShadowTransporentTouchesPassView)
@objcMembers
final class ShadowTransporentTouchesPassView: ShadowTransporentView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view === self {
            return nil
        }
        return view
    }
}
