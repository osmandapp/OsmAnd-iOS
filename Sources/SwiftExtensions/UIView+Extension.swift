//
//  UIView+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 16.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension UIView {
    @IBInspectable var borderColor: UIColor? {
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
        set {
            guard let color = newValue else {
                layer.borderColor = nil
                return
            }
            layer.borderColor = color.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.masksToBounds = true
            layer.cornerRadius = abs(CGFloat(Int(newValue * 100)) / 100)
        }
    }
}

extension UIView {
    /// Shadow color of view; also inspectable from Storyboard.
    @IBInspectable var shadowColor: UIColor? {
        get {
            guard let color = layer.shadowColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
        set {
            layer.shadowColor = newValue?.cgColor
        }
    }
    
    /// Shadow offset of view; also inspectable from Storyboard.
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    /// Shadow opacity of view; also inspectable from Storyboard.
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    ///Shadow radius of view; also inspectable from Storyboard.
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
}

extension UITableViewCell {
    @objc static var reuseIdentifier: String {
        String(describing: self)
    }
}

extension UICollectionViewCell {
    @objc static var reuseIdentifier: String {
        String(describing: self)
    }
}

extension UIView {
    class func fromNib<T: UIView>() -> T {
        Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as? UIViewController
            }
        }
        return nil
    }
}

extension UIView {
    var heightGreaterThanOrEqualConstraint: NSLayoutConstraint? {
        get {
            constraints.first(where: {
                $0.firstAttribute == .height && $0.relation == .greaterThanOrEqual
            })
        }
        set {
            setNeedsLayout()
        }
    }
    
    var heightEqualConstraint: NSLayoutConstraint? {
        get {
            constraints.first(where: {
                $0.firstAttribute == .height && $0.relation == .equal
            })
        }
        set {
            setNeedsLayout()
        }
    }
}

extension UIView {
    fileprivate struct Constants {
        static let externalBorderName = "externalBorder"
    }
    
    @discardableResult
    func addExternalBorder(borderWidth: CGFloat = 2.0,
                           borderColor: UIColor = .white,
                           cornerRadius: CGFloat = 0) -> CALayer {
        let externalBorder = CALayer()
        externalBorder.frame = CGRect(x: -borderWidth, y: -borderWidth, width: frame.size.width + 2 * borderWidth, height: frame.size.height + 2 * borderWidth)
        externalBorder.borderColor = borderColor.cgColor
        externalBorder.borderWidth = borderWidth
        if cornerRadius != 0 {
            externalBorder.cornerRadius = cornerRadius
        }
        externalBorder.name = Constants.externalBorderName
        
        layer.insertSublayer(externalBorder, at: 0)
        layer.masksToBounds = false
        
        return externalBorder
    }
    
    func removeExternalBorders() {
        layer.sublayers?.compactMap { $0 }
            .filter { $0.name == Constants.externalBorderName }
            .forEach { $0.removeFromSuperlayer() }
    }
    
    func removeExternalBorder(externalBorder: CALayer) {
        guard externalBorder.name == Constants.externalBorderName else { return }
        externalBorder.removeFromSuperlayer()
    }
}
