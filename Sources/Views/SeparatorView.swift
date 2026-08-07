//
//  SeparatorView.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class SeparatorAppearance: NSObject {
    static var color: UIColor {
        if #available(iOS 26.0, *) {
            return .customSeparatorSolid
        }
        return .customSeparator
    }

    private override init() {}

    static func thickness() -> CGFloat {
        thickness(forScreen: UIScreen.main)
    }

    static func thickness(forScreen screen: UIScreen) -> CGFloat {
        if #available(iOS 26.0, *) {
            return 1.0
        }
        return 1.0 / screen.scale
    }

    static func thickness(forView view: UIView) -> CGFloat {
        thickness(forScreen: view.window?.screen ?? UIScreen.main)
    }
}

class SeparatorView: UIView {
    @IBOutlet private weak var thicknessConstraint: NSLayoutConstraint? {
        didSet {
            updateThicknessConstraint()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: SeparatorAppearance.thickness(forView: self))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAppearance()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateThicknessConstraint()
        invalidateIntrinsicContentSize()
    }

#if TARGET_INTERFACE_BUILDER
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configureAppearance()
        updateThicknessConstraint()
        invalidateIntrinsicContentSize()
    }
#endif

    private func configureAppearance() {
        backgroundColor = SeparatorAppearance.color
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func updateThicknessConstraint() {
        thicknessConstraint?.constant = SeparatorAppearance.thickness(forView: self)
    }
}

final class VerticalSeparatorView: SeparatorView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: SeparatorAppearance.thickness(forView: self), height: UIView.noIntrinsicMetric)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAxisPriorities()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureAxisPriorities()
    }

#if TARGET_INTERFACE_BUILDER
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        configureAxisPriorities()
    }
#endif

    private func configureAxisPriorities() {
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }
}
