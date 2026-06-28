//
//  AstroContextMenuAdapter.swift
//  OsmAnd Maps
//
//  Ported from Android AstroContextMenuAdapter.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroContextMenuTheme {
    static var pageBackground: UIColor { .viewBg }
    static var cardBackground: UIColor { .groupBg }
    static var secondaryBackground: UIColor { .groupBgColorSecondary }
    static var actionBackground: UIColor { .buttonBgColorTertiary }
    static var actionTapBackground: UIColor { .buttonBgColorTap }
    static var iconButtonBackground: UIColor { UIColor(named: "iconButtonBgColor") ?? secondaryBackground }
    static var primaryText: UIColor { .textColorPrimary }
    static var secondaryText: UIColor { .textColorSecondary }
    static var tertiaryText: UIColor { UIColor(named: "textColorTertiary") ?? .textColorSecondary }
    static var activeText: UIColor { .textColorActive }
    static var activeIcon: UIColor { .iconColorActive }
    static var defaultIcon: UIColor { .iconColorDefault }
    static var secondaryIcon: UIColor { .iconColorSecondary }
    static var separator: UIColor { .customSeparator }
    static var primaryButton: UIColor { .buttonBgColorPrimary }
    static var secondaryButton: UIColor { .buttonBgColorSecondary }

    static var resolvedSeparator: UIColor {
        separator.currentMapThemeColor
    }
}

final class AstroContextMenuAdapter {
    private(set) var currentList: [AstroContextMenuItem] = []
    
    private let presentingController: UIViewController
    private let onDescriptionRead: (AstroDescriptionCardItem) -> Void
    private let onGalleryToggle: (String) -> Void
    private let onUpdateImage: () -> Void
    private let onKnowledgeCardAction: () -> Void
    private let onVisibilityResetToToday: () -> Void
    private let onVisibilityCursorChanged: (Int64) -> Void
    private let onScheduleResetPeriod: () -> Void
    private let onScheduleShiftPeriod: (Int) -> Void
    private let onScheduleSelectDate: (Date) -> Void
    private let onCatalogsToggleExpanded: () -> Void
    private let onCatalogClick: (Catalog) -> Void

    init(presentingController: UIViewController,
         onDescriptionRead: @escaping (AstroDescriptionCardItem) -> Void,
         onGalleryToggle: @escaping (String) -> Void,
         onUpdateImage: @escaping () -> Void,
         onKnowledgeCardAction: @escaping () -> Void,
         onVisibilityResetToToday: @escaping () -> Void,
         onVisibilityCursorChanged: @escaping (Int64) -> Void,
         onScheduleResetPeriod: @escaping () -> Void,
         onScheduleShiftPeriod: @escaping (Int) -> Void,
         onScheduleSelectDate: @escaping (Date) -> Void,
         onCatalogsToggleExpanded: @escaping () -> Void,
         onCatalogClick: @escaping (Catalog) -> Void) {
        self.presentingController = presentingController
        self.onDescriptionRead = onDescriptionRead
        self.onGalleryToggle = onGalleryToggle
        self.onUpdateImage = onUpdateImage
        self.onKnowledgeCardAction = onKnowledgeCardAction
        self.onVisibilityResetToToday = onVisibilityResetToToday
        self.onVisibilityCursorChanged = onVisibilityCursorChanged
        self.onScheduleResetPeriod = onScheduleResetPeriod
        self.onScheduleShiftPeriod = onScheduleShiftPeriod
        self.onScheduleSelectDate = onScheduleSelectDate
        self.onCatalogsToggleExpanded = onCatalogsToggleExpanded
        self.onCatalogClick = onCatalogClick
    }

    func submitItems(_ items: [AstroContextMenuItem], onCommitted: () -> Void = {}) {
        currentList = items
        onCommitted()
    }

    func getItemPosition(_ cardKey: AstroContextCardKey) -> Int {
        currentList.firstIndex { $0.key == cardKey } ?? -1
    }

    func makeCardViews() -> [UIView] {
        currentList.compactMap { item in
            switch item.key {
            case .description:
                guard let item = item as? AstroDescriptionCardItem else { return nil }
                return AstroDescriptionCardViewHolder.makeView(item: item, onReadClick: onDescriptionRead)
            case .visibility:
                guard let item = item as? AstroVisibilityCardItem else { return nil }
                return AstroVisibilityCardViewHolder.makeView(item: item,
                                                              onResetToToday: onVisibilityResetToToday,
                                                              onCursorTimeChanged: onVisibilityCursorChanged)
            case .schedule:
                guard let item = item as? AstroScheduleCardItem else { return nil }
                return AstroScheduleCardViewHolder.makeView(item: item,
                                                            onResetPeriod: onScheduleResetPeriod,
                                                            onShiftPeriod: onScheduleShiftPeriod,
                                                            onSelectDate: onScheduleSelectDate)
            case .catalogs:
                guard let item = item as? AstroCatalogsCardItem else { return nil }
                return AstroCatalogsCardViewHolder.makeView(item: item,
                                                            onToggleExpanded: onCatalogsToggleExpanded,
                                                            onCatalogClick: onCatalogClick)
            case .knowledge:
                guard let item = item as? AstroKnowledgeCardItem else { return nil }
                return AstroKnowledgeCardViewHolder.makeView(item: item, onActionClick: onKnowledgeCardAction)
            case .gallery:
                guard let item = item as? AstroGalleryCardItem else { return nil }
                return AstroGalleryCardViewHolder.makeView(item: item,
                                                           presentingController: presentingController,
                                                           onUpdateImage: onUpdateImage,
                                                           onToggle: onGalleryToggle)
            }
        }
    }
}

class AstroCardContainerView: UIView {
    let stack = UIStackView()

    init(title: String? = nil, iconName: String? = nil) {
        super.init(frame: .zero)
        setup(title: title, iconName: iconName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(title: String?, iconName: String?) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AstroContextMenuTheme.cardBackground
        layer.cornerRadius = 26
        layer.masksToBounds = true

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        if title != nil || iconName != nil {
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 8
            if let iconName {
                let imageView = UIImageView(image: AstroIcon.template(iconName))
                imageView.tintColor = AstroContextMenuTheme.activeIcon
                imageView.contentMode = .scaleAspectFit
                imageView.widthAnchor.constraint(equalToConstant: 22).isActive = true
                imageView.heightAnchor.constraint(equalToConstant: 22).isActive = true
                row.addArrangedSubview(imageView)
            }
            if let title {
                let label = UILabel()
                label.text = title
                label.textColor = AstroContextMenuTheme.primaryText
                label.font = .systemFont(ofSize: 16, weight: .bold)
                label.numberOfLines = 0
                row.addArrangedSubview(label)
            }
            stack.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            backgroundColor = AstroContextMenuTheme.cardBackground
        }
    }
}
