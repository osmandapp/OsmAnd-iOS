//
//  OACollapsablePoiView.swift
//  OsmAnd
//
//  Created by Max Kojin on 14/05/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class OACollapsablePoiView: OACollapsableView  {
    
    private let kButtonHeight: CGFloat = 36.0

    private var titles = [String]()
    private var amenities = [OAPOI]()
    private var buttons = [OAButton]()
    private var selectedButtonIndex = 0
    
    func setData(titles: [String], amenities: [OAPOI]) {
        self.amenities = amenities
        self.titles = titles
        buildViews()
    }
    
    func updateLayout(width: CGFloat) {
        var y: CGFloat = 0.0
        var viewHeight: CGFloat = 0.0
        var i = 0
        for button in buttons {
            if i > 0 {
                y += kButtonHeight + 10.0
                viewHeight += 10.0
            }
            
            let height: CGFloat = kButtonHeight
            button.frame = CGRect(x: kMarginLeft, y: y, width: width - kMarginLeft - kMarginRight, height: height)
            viewHeight += button.frame.size.height
            i += 1
        }
        
        viewHeight += 8.0
        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: width, height: viewHeight)
    }
    
    private func buildViews() {
        for i in 0..<amenities.count {
            let btn = createButton(title: titles[i])
            btn.tag = i
            self.addSubview(btn)
            buttons.append(btn)
        }
    }
    
    private func createButton(title: String) -> OAButton {
        let btn = OAButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12.0, bottom: 0, right: 12.0)
        btn.titleLabel?.lineBreakMode = .byTruncatingTail
        btn.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        btn.layer.cornerRadius = 4.0
        btn.layer.masksToBounds = true
        btn.layer.borderWidth = 0.8
        btn.layer.borderColor = UIColor.customSeparator.cgColor
        btn.setBackgroundImage(OAUtilities.image(with: .clear), for: .normal)
        btn.tintColor = UIColor.iconColorActive
        btn.delegate = self
        return btn
    }
    
    override func copy(_ sender: Any?) {
        guard buttons.count > selectedButtonIndex else { return }
        let button = buttons[selectedButtonIndex]
        let pasteboard = UIPasteboard.general
        pasteboard.string = button.titleLabel?.text
    }
    
    private func updateButtonBorderColor() {
        for button in buttons {
            button.layer.borderColor = UIColor.customSeparator.cgColor
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateButtonBorderColor()
        }
    }
    
    override func adjustHeight(forWidth width: CGFloat) {
        updateLayout(width: width)
    }
}

extension OACollapsablePoiView: OAButtonDelegate {
    
    func onButtonTapped(_ tag: Int) {
        guard amenities.count > tag else { return }
        let amenity = amenities[tag]
        if let targetPoint = OAPOILayer.getTargetPoint(amenity) {
            targetPoint.centerMap = true
            OARootViewController.instance().mapPanel.showContextMenu(with: [targetPoint], selectedObjects: [], touchPointLatLon: CLLocation(latitude: targetPoint.location.latitude, longitude: targetPoint.location.longitude))
        }
    }
    
    func onButtonLongPressed(_ tag: Int) {
        selectedButtonIndex = tag
        guard buttons.count > selectedButtonIndex else { return }
        OAUtilities.showMenu(in: self, from: buttons[selectedButtonIndex])
    }
}
