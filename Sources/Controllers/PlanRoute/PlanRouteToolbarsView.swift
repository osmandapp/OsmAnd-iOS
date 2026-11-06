//
//  PlanRouteToolbarsView.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteTopToolbarView: TouchesPassView {
    static let contentHeight: CGFloat = 70

    private static let edgeInset: CGFloat = 16
    private static let buttonSpacing: CGFloat = 8

    var onClose: (() -> Void)?
    var onSave: (() -> Void)?

    var closeButtonSourceView: UIView { closeButton }
    var optionsButtonSourceView: UIView { optionsButton }

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
    private let closeButton = PlanRouteButtonFactory.iconMapButton(image: .icCustomCancel)
    private let optionsButton = PlanRouteButtonFactory.iconMapButton(image: .icCustomOverflowMenuStroke)

    private lazy var saveButton = PlanRouteButtonFactory.primaryButton(title: localizedString("shared_string_save"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateMapTheme() {
        closeButton.updateColors(forPressedState: false)
        optionsButton.updateColors(forPressedState: false)
        saveButton.updateColors(forPressedState: false)
        backgroundContainerView.backgroundColor = closeButton.backgroundColor
        titleLabel.textColor = closeButton.tintColor
    }

    private func setupView() {
        backgroundColor = .clear

        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .semibold, maximumSize: 22)
        updateMapTheme()
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

        setupBackgroundView()

        let inset = Self.edgeInset
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: inset),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Self.buttonSpacing),

            trailingStack.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -inset),
            trailingStack.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingStack.leadingAnchor, constant: -20)
        ])

        closeButton.accessibilityLabel = localizedString("shared_string_close")
        optionsButton.accessibilityLabel = localizedString("shared_string_options")
        closeButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(onSaveTapped), for: .touchUpInside)
    }

    private func setupBackgroundView() {
        backgroundContainerView.layer.cornerRadius = PlanRouteButtonFactory.toolbarButtonSize / 2
        backgroundContainerView.isUserInteractionEnabled = false
        backgroundContainerView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(backgroundContainerView, at: 0)

        NSLayoutConstraint.activate([
            backgroundContainerView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -12),
            backgroundContainerView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            backgroundContainerView.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            backgroundContainerView.heightAnchor.constraint(equalTo: closeButton.heightAnchor)
        ])
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

    private let undoButton = PlanRouteButtonFactory.bottomToolbarIconButton(image: .icCustomUndo)
    private let redoButton = PlanRouteButtonFactory.bottomToolbarIconButton(image: .icCustomRedo)

    private lazy var addPoiButton = PlanRouteButtonFactory.bottomToolbarLabeledButton(title: localizedString("poi"), image: .icCustomAdd)
    private lazy var routeButton = PlanRouteButtonFactory.bottomToolbarLabeledButton(title: localizedString("layer_route"), image: .icCustomAdd, imagePlacement: .trailing)

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

        centerStack.setContentHuggingPriority(.required, for: .horizontal)
        centerStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        [addPoiButton, routeButton].forEach {
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            $0.titleLabel?.numberOfLines = 1
            $0.titleLabel?.lineBreakMode = .byTruncatingTail
        }

        let inset = Self.edgeInset
        NSLayoutConstraint.activate([
            addPoiButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            addPoiButton.topAnchor.constraint(equalTo: topAnchor),
            addPoiButton.widthAnchor.constraint(greaterThanOrEqualToConstant: PlanRouteButtonFactory.bottomButtonHeight),

            routeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            routeButton.centerYAnchor.constraint(equalTo: addPoiButton.centerYAnchor),
            routeButton.widthAnchor.constraint(greaterThanOrEqualToConstant: PlanRouteButtonFactory.bottomButtonHeight),

            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: addPoiButton.centerYAnchor),

            addPoiButton.trailingAnchor.constraint(lessThanOrEqualTo: centerStack.leadingAnchor, constant: -Self.buttonSpacing),
            routeButton.leadingAnchor.constraint(greaterThanOrEqualTo: centerStack.trailingAnchor, constant: Self.buttonSpacing)
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
