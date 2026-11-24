//
//  SearchSortFilterChipsView.swift
//  OsmAnd Maps
//
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

// MARK: - Models

enum StarMapSearchSortFilterChipSelectionMode {
    case single
    case multiple
    case toggle
}

struct StarMapSearchSortFilterChipOption {
    let id: String
    let title: String
    let image: UIImage?
    let originalSizeImage: UIImage?
    let isSelected: Bool
}

struct StarMapSearchSortFilterChipSection {
    let options: [StarMapSearchSortFilterChipOption]
}

struct SearchSortFilterChipGroup {
    let id: String
    let chipTitle: String
    let chipImage: UIImage?
    let selectionMode: StarMapSearchSortFilterChipSelectionMode
    let sections: [StarMapSearchSortFilterChipSection]
    let isToggleOn: Bool
    let menuTitle: String
    let isEnabled: Bool

    init(id: String,
         chipTitle: String,
         chipImage: UIImage?,
         selectionMode: StarMapSearchSortFilterChipSelectionMode,
         sections: [StarMapSearchSortFilterChipSection] = [],
         isToggleOn: Bool = false,
         menuTitle: String = "",
         isEnabled: Bool = true) {
        self.id = id
        self.chipTitle = chipTitle
        self.chipImage = chipImage
        self.selectionMode = selectionMode
        self.sections = sections
        self.isToggleOn = isToggleOn
        self.menuTitle = menuTitle
        self.isEnabled = isEnabled
    }
}

// MARK: - Protocols

protocol StarMapSearchSortFilterChipsDataSource: AnyObject {
    func chipGroups(for chipsView: StarMapSearchSortFilterChipsView) -> [SearchSortFilterChipGroup]
}

protocol StarMapSearchSortFilterChipsDelegate: AnyObject {
    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didSelectOption optionId: String, inGroup groupId: String)
    func chipsView(_ chipsView: StarMapSearchSortFilterChipsView, didToggleGroup groupId: String, isOn: Bool)
}

// MARK: - Chip button

private enum StarMapSearchSortFilterChipStyle {
    case menu
    case toggleOff
    case toggleOn
}

private final class StarMapSearchSortFilterChipButton: UIButton {

    private let chevronView = UIImageView()
    private var showsMenuChevron = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configureForMenu() {
        showsMenuAsPrimaryAction = true
        showsMenuChevron = true
        chevronView.isHidden = false
    }

    func configureForToggle(action: UIAction) {
        showsMenuAsPrimaryAction = false
        menu = nil
        showsMenuChevron = false
        chevronView.isHidden = true
        removeTarget(nil, action: nil, for: .touchUpInside)
        addAction(action, for: .touchUpInside)
    }

    func apply(title: String, image: UIImage?, style: StarMapSearchSortFilterChipStyle, isEnabled: Bool = true) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.image = image
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.title = title
        config.titleLineBreakMode = .byTruncatingTail
        let textColor: UIColor = !isEnabled ? .textColorTertiary : style == .toggleOn ? .filterChipTextActive : .buttonTextColorSecondary
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
            outgoing.foregroundColor = textColor
            return outgoing
        }

        switch style {
        case .menu:
            config.baseBackgroundColor = .filterChipBGDefault
            config.baseForegroundColor = .filterChipIconDefault
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: showsMenuChevron ? 28 : 10)
        case .toggleOff:
            config.baseBackgroundColor = .filterChipBGDefault
            config.baseForegroundColor = .filterChipIconDefault
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 10)
        case .toggleOn:
            config.baseBackgroundColor = .filterChipBGActive
            config.baseForegroundColor = .filterChipIconActive
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 10)
        }
        if image == nil && style != .menu {
            config.contentInsets.leading = config.contentInsets.trailing
        }
        if !isEnabled {
            config.baseForegroundColor = .iconColorDisabled
        }
        configuration = config
        self.isEnabled = isEnabled
        chevronView.tintColor = isEnabled ? .iconColorActive : .iconColorDisabled
    }
    
    private func setup() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.zPosition = 1
        
        changesSelectionAsPrimaryAction = false
        titleLabel?.lineBreakMode = .byTruncatingTail
        titleLabel?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        chevronView.image = UIImage(
            systemName: "chevron.up.chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        )
        chevronView.tintColor = .iconColorActive
        chevronView.translatesAutoresizingMaskIntoConstraints = false
        chevronView.isUserInteractionEnabled = false
        addSubview(chevronView)

        NSLayoutConstraint.activate([
            chevronView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            chevronView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
}

// MARK: - Scroll view

private final class StarMapSearchSortFilterChipsScrollView: UIScrollView {

    private var lastMaxContentOffsetX: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        guard effectiveUserInterfaceLayoutDirection == .rightToLeft else {
            return
        }
        let maxContentOffsetX = max(0, contentSize.width - bounds.width)
        guard maxContentOffsetX != lastMaxContentOffsetX else {
            return
        }
        contentOffset.x = min(maxContentOffsetX, max(0, contentOffset.x + maxContentOffsetX - lastMaxContentOffsetX))
        lastMaxContentOffsetX = maxContentOffsetX
    }
}

// MARK: - Chips view

final class StarMapSearchSortFilterChipsView: UIView {

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let chipSpacing: CGFloat = 8
        static let barHeight: CGFloat = 36
    }

    weak var dataSource: StarMapSearchSortFilterChipsDataSource?
    weak var delegate: StarMapSearchSortFilterChipsDelegate?

    private let scrollView = StarMapSearchSortFilterChipsScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private var chipButtons: [String: StarMapSearchSortFilterChipButton] = [:]
    private var chipGroups: [SearchSortFilterChipGroup] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Public API

    func reloadData() {
        chipGroups = dataSource?.chipGroups(for: self) ?? []
        rebuildChips()
        updateChipAppearances()
        updateChipMenus()
    }
    
    // MARK: - Setup
    
    private func setup() {
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.clipsToBounds = false

        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.chipSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)
        scrollView.addSubview(contentView)
        addSubview(scrollView)

        let contentFittingWidth = contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        contentFittingWidth.priority = .defaultLow

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.barHeight),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            contentView.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
            contentFittingWidth,

            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Chips

    private func rebuildChips() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        chipButtons.removeAll()

        for group in chipGroups {
            let button = StarMapSearchSortFilterChipButton(type: .system)

            switch group.selectionMode {
            case .single, .multiple:
                button.configureForMenu()
            case .toggle:
                button.configureForToggle(action: UIAction { [weak self] _ in
                    guard let self else {
                        return
                    }
                    delegate?.chipsView(self, didToggleGroup: group.id, isOn: !group.isToggleOn)
                })
            }

            chipButtons[group.id] = button
            stackView.addArrangedSubview(button)
        }
    }

    private func updateChipAppearances() {
        for group in chipGroups {
            guard let button = chipButtons[group.id] else {
                continue
            }
            switch group.selectionMode {
            case .single, .multiple:
                button.apply(title: group.chipTitle, image: group.chipImage, style: .menu, isEnabled: group.isEnabled)
            case .toggle:
                button.apply(
                    title: group.chipTitle,
                    image: group.chipImage,
                    style: group.isToggleOn ? .toggleOn : .toggleOff,
                    isEnabled: group.isEnabled
                )
            }
        }
    }

    private func updateChipMenus() {
        for group in chipGroups {
            guard let button = chipButtons[group.id] else {
                continue
            }
            switch group.selectionMode {
            case .single, .multiple:
                button.menu = makeMenu(for: group)
            case .toggle:
                button.menu = nil
            }
        }
    }

    private func makeMenu(for group: SearchSortFilterChipGroup) -> UIMenu {
        var children: [UIMenuElement] = []
        for (index, section) in group.sections.enumerated() {
            let actions = section.options.map { option in
                makeMenuAction(option: option, group: group)
            }
            if index == 0 {
                children.append(contentsOf: actions)
            } else {
                children.append(UIMenu(title: "", options: .displayInline, children: actions))
            }
        }
        return UIMenu(title: group.menuTitle, children: children)
    }

    private func makeMenuAction(option: StarMapSearchSortFilterChipOption, group: SearchSortFilterChipGroup) -> UIAction {
        UIAction(
            title: option.title,
            image: option.originalSizeImage,
            state: option.isSelected ? .on : .off
        ) { [weak self] _ in
            guard let self else {
                return
            }
            delegate?.chipsView(self, didSelectOption: option.id, inGroup: group.id)
        }
    }
}
