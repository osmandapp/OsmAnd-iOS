//
//  PlanRouteToolbarsView.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteTopToolbarView: UIView {
    static let contentHeight: CGFloat = 56

    private static let edgeInset: CGFloat = 16
    private static let buttonSpacing: CGFloat = 8
    private static let backgroundFadeStartLocation: NSNumber = 0.58
    private static let backgroundFadeEndLocation: NSNumber = 1
    private static let dimmingSecondLocation: NSNumber = 0.22
    private static let dimmingThirdLocation: NSNumber = 0.6
    private static let dimmingEndLocation: NSNumber = 1
    private static let lightTopDimmingAlpha: CGFloat = 0.24
    private static let lightSecondDimmingAlpha: CGFloat = 0.16
    private static let lightThirdDimmingAlpha: CGFloat = 0.07
    private static let darkTopDimmingAlpha: CGFloat = 0.3
    private static let darkSecondDimmingAlpha: CGFloat = 0.22
    private static let darkThirdDimmingAlpha: CGFloat = 0.1

    var onClose: (() -> Void)?
    var onSave: (() -> Void)?

    var titleText: String? {
        didSet { titleLabel.text = titleText }
    }

    var optionsMenu: UIMenu? {
        didSet {
            optionsButton.menu = optionsMenu
            optionsButton.showsMenuAsPrimaryAction = optionsMenu != nil
        }
    }

    var isSaveButtonVisible = true {
        didSet { saveButton.isHidden = !isSaveButtonVisible }
    }

    var isSaveButtonEnabled = true {
        didSet { saveButton.isEnabled = isSaveButtonEnabled }
    }

    private let backgroundContainerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_custom_cancel"))
    private let optionsButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_custom_overflow_menu_stroke"))
    private let dimmingView = UIView()
    private let backgroundMaskLayer = CAGradientLayer()
    private let dimmingGradientLayer = CAGradientLayer()

    private lazy var saveButton = PlanRouteButtonFactory.primaryButton(title: localizedString("shared_string_save"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyBackgroundEffect()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard backgroundContainerView.bounds.size != .zero else { return }
        updateBackgroundLayers()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        return hitView is UIControl ? hitView : nil
    }

    private func setupView() {
        backgroundColor = .clear
        setupBackgroundView()

        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .semibold, maximumSize: 22)
        titleLabel.textColor = .textColorPrimary
        titleLabel.textAlignment = .natural
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let trailingStack = UIStackView(arrangedSubviews: [optionsButton, saveButton])
        trailingStack.spacing = Self.buttonSpacing
        trailingStack.alignment = .center

        [closeButton, titleLabel, trailingStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let inset = Self.edgeInset
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: inset),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Self.buttonSpacing),

            trailingStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -inset),
            trailingStack.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingStack.leadingAnchor, constant: -Self.buttonSpacing)
        ])

        closeButton.accessibilityLabel = localizedString("shared_string_close")
        optionsButton.accessibilityLabel = localizedString("shared_string_options")
        closeButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(onSaveTapped), for: .touchUpInside)
    }

    private func setupBackgroundView() {
        backgroundContainerView.backgroundColor = .clear
        backgroundContainerView.isUserInteractionEnabled = false
        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(backgroundContainerView, at: 0)

        dimmingView.backgroundColor = .clear
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainerView.addSubview(dimmingView)

        NSLayoutConstraint.activate([
            backgroundContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundContainerView.topAnchor.constraint(equalTo: topAnchor),
            backgroundContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            dimmingView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            dimmingView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])

        backgroundMaskLayer.startPoint = CGPoint(x: 0.5, y: 0)
        backgroundMaskLayer.endPoint = CGPoint(x: 0.5, y: 1)
        backgroundContainerView.layer.mask = backgroundMaskLayer

        dimmingGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        dimmingGradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        dimmingView.layer.addSublayer(dimmingGradientLayer)
    }

    private func applyBackgroundEffect() {
        let isNightMode = OAAppSettings.sharedManager().nightMode
        backgroundContainerView.subviews
            .filter { $0 !== dimmingView }
            .forEach { $0.removeFromSuperview() }

        if #available(iOS 26.0, *) {
            let glass = UIGlassEffect(style: .regular)
            glass.tintColor = isNightMode
                ? UIColor.black.withAlphaComponent(0.14)
                : UIColor.white.withAlphaComponent(0.1)

            let effectView = UIVisualEffectView(effect: glass)
            effectView.isUserInteractionEnabled = false
            effectView.overrideUserInterfaceStyle = isNightMode ? .dark : .light
            effectView.translatesAutoresizingMaskIntoConstraints = false
            backgroundContainerView.insertSubview(effectView, at: 0)

            NSLayoutConstraint.activate([
                effectView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
                effectView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
                effectView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
                effectView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
            ])
        } else {
            backgroundContainerView.addBlurEffect(!isNightMode, cornerRadius: 0, padding: 0)
        }

        updateBackgroundLayers()
    }

    private func updateBackgroundLayers() {
        let isCompactLayout = traitCollection.verticalSizeClass == .compact
        let fadeStartLocation = Self.backgroundFadeStartLocation
        let fadeEndLocation = Self.backgroundFadeEndLocation
        let dimmingSecondLocation = Self.dimmingSecondLocation
        let dimmingThirdLocation = Self.dimmingThirdLocation
        let dimmingEndLocation = Self.dimmingEndLocation
        let isNightMode = OAAppSettings.sharedManager().nightMode
        let topDimmingAlpha = isNightMode ? Self.darkTopDimmingAlpha : Self.lightTopDimmingAlpha
        let secondDimmingAlpha = isNightMode ? Self.darkSecondDimmingAlpha : Self.lightSecondDimmingAlpha
        let thirdDimmingAlpha = isNightMode ? Self.darkThirdDimmingAlpha : Self.lightThirdDimmingAlpha

        backgroundContainerView.isHidden = isCompactLayout
        guard !isCompactLayout else { return }

        backgroundMaskLayer.frame = backgroundContainerView.bounds
        backgroundContainerView.layer.mask = backgroundMaskLayer
        backgroundMaskLayer.colors = [
            UIColor.black.cgColor,
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        backgroundMaskLayer.locations = [NSNumber(value: 0), fadeStartLocation, fadeEndLocation]

        dimmingGradientLayer.frame = dimmingView.bounds
        dimmingGradientLayer.colors = [
            UIColor.black.withAlphaComponent(topDimmingAlpha).cgColor,
            UIColor.black.withAlphaComponent(secondDimmingAlpha).cgColor,
            UIColor.black.withAlphaComponent(thirdDimmingAlpha).cgColor,
            UIColor.clear.cgColor
        ]
        dimmingGradientLayer.locations = [NSNumber(value: 0), dimmingSecondLocation, dimmingThirdLocation, dimmingEndLocation]
    }

    @objc private func onCloseTapped() {
        onClose?()
    }

    @objc private func onSaveTapped() {
        onSave?()
    }
}

final class PlanRouteBottomToolbarView: UIView {
    private static let edgeInset: CGFloat = 16
    private static let buttonSpacing: CGFloat = 8

    var onAddPoi: (() -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onAddRoutePoint: (() -> Void)?

    var isUndoEnabled = false {
        didSet { undoButton.isEnabled = isUndoEnabled }
    }

    var isRedoEnabled = false {
        didSet { redoButton.isEnabled = isRedoEnabled }
    }

    private let undoButton = PlanRouteButtonFactory.bottomToolbarIconButton(image: .templateImageNamed("ic_custom_undo"))
    private let redoButton = PlanRouteButtonFactory.bottomToolbarIconButton(image: .templateImageNamed("ic_custom_redo"))

    private lazy var addPoiButton = PlanRouteButtonFactory.bottomToolbarLabeledButton(title: localizedString("poi"), image: .templateImageNamed("ic_custom_add"))
    private lazy var routeButton = PlanRouteButtonFactory.bottomToolbarLabeledButton(title: localizedString("layer_route"), image: .templateImageNamed("ic_custom_add"), imagePlacement: .trailing)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .clear

        let centerStack = UIStackView(arrangedSubviews: [undoButton, redoButton])
        centerStack.spacing = Self.buttonSpacing
        centerStack.alignment = .center

        [addPoiButton, centerStack, routeButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let inset = Self.edgeInset
        NSLayoutConstraint.activate([
            addPoiButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            addPoiButton.topAnchor.constraint(equalTo: topAnchor),

            routeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            routeButton.centerYAnchor.constraint(equalTo: addPoiButton.centerYAnchor),

            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: addPoiButton.centerYAnchor)
        ])

        addPoiButton.addTarget(self, action: #selector(onAddPoiTapped), for: .touchUpInside)
        undoButton.accessibilityLabel = localizedString("shared_string_undo")
        redoButton.accessibilityLabel = localizedString("shared_string_redo")
        undoButton.addTarget(self, action: #selector(onUndoTapped), for: .touchUpInside)
        redoButton.addTarget(self, action: #selector(onRedoTapped), for: .touchUpInside)
        routeButton.addTarget(self, action: #selector(onRouteTapped), for: .touchUpInside)
    }

    @objc private func onAddPoiTapped() {
        onAddPoi?()
    }

    @objc private func onUndoTapped() {
        onUndo?()
    }

    @objc private func onRedoTapped() {
        onRedo?()
    }

    @objc private func onRouteTapped() {
        onAddRoutePoint?()
    }
}
