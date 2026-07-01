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

    init(id: String,
         chipTitle: String,
         chipImage: UIImage?,
         selectionMode: StarMapSearchSortFilterChipSelectionMode,
         sections: [StarMapSearchSortFilterChipSection] = [],
         isToggleOn: Bool = false) {
        self.id = id
        self.chipTitle = chipTitle
        self.chipImage = chipImage
        self.selectionMode = selectionMode
        self.sections = sections
        self.isToggleOn = isToggleOn
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

    func apply(title: String, image: UIImage?, style: StarMapSearchSortFilterChipStyle) {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.image = image
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.title = title
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
            outgoing.foregroundColor = style == .toggleOn ? .filterChipTextActive : .buttonTextColorSecondary
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
        configuration = config
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

// MARK: - Chips view

final class StarMapSearchSortFilterChipsView: UIView {

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let chipSpacing: CGFloat = 8
        static let barHeight: CGFloat = 36
    }

    weak var dataSource: StarMapSearchSortFilterChipsDataSource?
    weak var delegate: StarMapSearchSortFilterChipsDelegate?

    private let scrollView = UIScrollView()
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

        scrollView.addSubview(stackView)
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.barHeight),

            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Layout.horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Layout.horizontalPadding),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
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
                button.apply(title: group.chipTitle, image: group.chipImage, style: .menu)
            case .toggle:
                button.apply(
                    title: group.chipTitle,
                    image: group.chipImage,
                    style: group.isToggleOn ? .toggleOn : .toggleOff
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
        return UIMenu(children: children)
    }

    private func makeMenuAction(option: StarMapSearchSortFilterChipOption, group: SearchSortFilterChipGroup) -> UIAction {
        UIAction(
            title: option.title,
            image: option.image,
            state: option.isSelected ? .on : .off
        ) { [weak self] _ in
            guard let self else {
                return
            }
            delegate?.chipsView(self, didSelectOption: option.id, inGroup: group.id)
        }
    }
}
