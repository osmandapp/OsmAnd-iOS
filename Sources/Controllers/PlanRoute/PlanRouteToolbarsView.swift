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

    private let titleLabel = UILabel()
    private let closeButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_navbar_close"))
    private let optionsButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_custom_overflow_menu_stroke"))

    private lazy var saveButton = PlanRouteButtonFactory.primaryButton(title: localizedString("shared_string_save"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        return hitView is UIControl ? hitView : nil
    }

    private func setupView() {
        backgroundColor = .clear

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

        closeButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(onSaveTapped), for: .touchUpInside)
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

    private let undoButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_custom_undo"), size: PlanRouteButtonFactory.bottomButtonHeight)
    private let redoButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_custom_redo"), size: PlanRouteButtonFactory.bottomButtonHeight)

    private lazy var addPoiButton = PlanRouteButtonFactory.labeledButton(title: localizedString("poi"), image: .templateImageNamed("ic_custom_add"))
    private lazy var routeButton = PlanRouteButtonFactory.labeledButton(title: localizedString("layer_route"), image: .templateImageNamed("ic_custom_add"), imagePlacement: .trailing)

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
