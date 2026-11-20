//
//  PointRowContentView.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

struct PointSecondaryContent {
    let formattedDistance: String?
    let direction: CGFloat
    let directionColor: UIColor?
    let address: String?
    let date: String?
    let trailingText: String?
    let isDateFirst: Bool

    init(formattedDistance: String?, direction: CGFloat, directionColor: UIColor? = nil, address: String?, date: String?, trailingText: String? = nil, isDateFirst: Bool = false) {
        self.formattedDistance = formattedDistance
        self.direction = direction
        self.directionColor = directionColor
        self.address = address
        self.date = date
        self.trailingText = trailingText
        self.isDateFirst = isDateFirst
    }
    
    func attributedText() -> NSAttributedString? {
        let font = UIFont.scaledSystemFont(ofSize: PointContentConfiguration.secondaryTextSize)
        let directionAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: directionColor ?? UIColor.textColorDirectionActive]
        let directionIconColor = directionColor ?? UIColor.iconColorDirectionActive
        let secondaryAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.textColorSecondary]
        let result = NSMutableAttributedString()
        if isDateFirst {
            append(date, to: result, attributes: secondaryAttributes)
            appendDistance(to: result, font: font, directionAttributes: directionAttributes, directionIconColor: directionIconColor, separatorAttributes: secondaryAttributes)
            append(address, to: result, attributes: secondaryAttributes)
        } else {
            appendDistance(to: result, font: font, directionAttributes: directionAttributes, directionIconColor: directionIconColor, separatorAttributes: secondaryAttributes)
            append(address, to: result, attributes: secondaryAttributes)
            append(date, to: result, attributes: secondaryAttributes)
        }

        append(trailingText, to: result, attributes: secondaryAttributes)
        return result.length > 0 ? result : nil
    }

    private func append(_ text: String?, to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard let text, !text.isEmpty else { return }
        appendSeparatorIfNeeded(to: result, attributes: attributes)
        result.append(NSAttributedString(string: text, attributes: attributes))
    }

    private func appendDistance(to result: NSMutableAttributedString, font: UIFont, directionAttributes: [NSAttributedString.Key: Any], directionIconColor: UIColor, separatorAttributes: [NSAttributedString.Key: Any]) {
        guard let formattedDistance, !formattedDistance.isEmpty else { return }
        appendSeparatorIfNeeded(to: result, attributes: separatorAttributes)
        if let directionIcon = directionIcon(font: font, color: directionIconColor) {
            result.append(directionIcon)
        }

        result.append(NSAttributedString(string: formattedDistance, attributes: directionAttributes))
    }

    private func appendSeparatorIfNeeded(to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard result.length > 0 else { return }
        result.append(NSAttributedString(string: " • ", attributes: attributes))
    }

    private func directionIcon(font: UIFont, color: UIColor) -> NSAttributedString? {
        let size = UIFontMetrics.default.scaledValue(for: PointContentConfiguration.directionIconSize)
        guard let image = OAUtilities.resize(.icSmallDirection, newSize: CGSize(width: size, height: size))?.withTintColor(color) else { return nil }
        let rotatedImage = image.rotatedWithinBounds(by: direction)
        let attachment = NSTextAttachment()
        attachment.image = rotatedImage
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - rotatedImage.size.height) / 2, width: rotatedImage.size.width, height: rotatedImage.size.height)
        return NSAttributedString(attachment: attachment)
    }
}

struct PointContentConfiguration: UIContentConfiguration {
    enum IconStyle {
        case plain
        case plate
    }

    static let estimatedRowHeight: CGFloat = 66

    fileprivate static let iconSize: CGFloat = 36
    fileprivate static let plateSize: CGFloat = 42
    fileprivate static let plateIconSize: CGFloat = 24
    fileprivate static let plateCornerRadius: CGFloat = 10
    fileprivate static let plateSpacing: CGFloat = 12
    fileprivate static let plateVerticalInset: CGFloat = 12
    fileprivate static let directionIconSize: CGFloat = 18
    fileprivate static let secondaryTextSize: CGFloat = 15

    var icon: UIImage?
    let title: String
    let isVisible: Bool
    let iconStyle: IconStyle

    var secondaryContent: PointSecondaryContent?
    var primaryTextLayoutGuideHandler: ((UILayoutGuide?) -> Void)?

    init(icon: UIImage?, title: String, isVisible: Bool = true, iconStyle: IconStyle = .plain, secondaryContent: PointSecondaryContent?) {
        self.icon = icon
        self.title = title
        self.isVisible = isVisible
        self.iconStyle = iconStyle
        self.secondaryContent = secondaryContent
    }

    static func backgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listGroupedCell()
        configuration.backgroundColor = .groupBg
        return configuration
    }

    static func backgroundConfiguration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
        if !state.isHighlighted && !state.isSelected {
            configuration.backgroundColor = .groupBg
        }
        return configuration
    }

    static func applyHighlightableBackground(to cell: UITableViewCell) {
        cell.backgroundConfiguration = backgroundConfiguration()
        cell.configurationUpdateHandler = { cell, state in
            cell.backgroundConfiguration = Self.backgroundConfiguration(for: state)
        }
    }

    func makeContentView() -> UIView & UIContentView {
        PointRowContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PointContentConfiguration {
        self
    }
}

private final class PointRowContentView: UIView, UIContentView, PrimaryTextLayoutGuideProviding {
    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let configuration = newValue as? PointContentConfiguration else { return }
            let shouldUpdateOnlySecondaryContent = hasSamePrimaryContent(as: configuration)
            appliedConfiguration = configuration
            if shouldUpdateOnlySecondaryContent {
                applySecondaryContent(configuration.secondaryContent)
            } else {
                apply(configuration)
            }
        }
    }
    
    var primaryTextLayoutGuide: UILayoutGuide? { rowContentView.textLayoutGuide }

    private let rowContentView = UIListContentView(configuration: .cell())
    private let plateView = UIView()
    private let plateIconView = UIImageView()

    private var appliedConfiguration: PointContentConfiguration
    private var plainConstraints: [NSLayoutConstraint] = []
    private var plateConstraints: [NSLayoutConstraint] = []

    init(configuration: PointContentConfiguration) {
        appliedConfiguration = configuration
        super.init(frame: .zero)
        setupView()
        apply(configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        appliedConfiguration.primaryTextLayoutGuideHandler?(superview == nil ? nil : primaryTextLayoutGuide)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        apply(appliedConfiguration)
    }

    private func hasSamePrimaryContent(as configuration: PointContentConfiguration) -> Bool {
        appliedConfiguration.icon === configuration.icon
        && appliedConfiguration.title == configuration.title
        && appliedConfiguration.isVisible == configuration.isVisible
        && appliedConfiguration.iconStyle == configuration.iconStyle
    }

    private func setupView() {
        rowContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowContentView)

        plateView.backgroundColor = .imagePlaceholderBg
        plateView.layer.cornerRadius = PointContentConfiguration.plateCornerRadius
        plateView.layer.cornerCurve = .continuous
        plateView.clipsToBounds = true
        plateView.isHidden = true
        plateView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(plateView)

        plateIconView.contentMode = .scaleAspectFit
        plateIconView.tintColor = .iconColorSelected
        plateIconView.translatesAutoresizingMaskIntoConstraints = false
        plateView.addSubview(plateIconView)

        plainConstraints = [
            rowContentView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ]
        plateConstraints = [
            rowContentView.leadingAnchor.constraint(equalTo: plateView.trailingAnchor, constant: PointContentConfiguration.plateSpacing),
            plateView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: PointContentConfiguration.plateVerticalInset),
            plateView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -PointContentConfiguration.plateVerticalInset)
        ]
        NSLayoutConstraint.activate(plainConstraints + [
            rowContentView.topAnchor.constraint(equalTo: topAnchor),
            rowContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            plateView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            plateView.centerYAnchor.constraint(equalTo: centerYAnchor),
            plateView.widthAnchor.constraint(equalToConstant: PointContentConfiguration.plateSize),
            plateView.heightAnchor.constraint(equalToConstant: PointContentConfiguration.plateSize),
            plateIconView.centerXAnchor.constraint(equalTo: plateView.centerXAnchor),
            plateIconView.centerYAnchor.constraint(equalTo: plateView.centerYAnchor),
            plateIconView.widthAnchor.constraint(equalToConstant: PointContentConfiguration.plateIconSize),
            plateIconView.heightAnchor.constraint(equalToConstant: PointContentConfiguration.plateIconSize)
        ])
    }

    private func applyIconStyle(_ iconStyle: PointContentConfiguration.IconStyle) {
        let isPlate = iconStyle == .plate
        preservesSuperviewLayoutMargins = isPlate
        plateView.isHidden = !isPlate
        NSLayoutConstraint.deactivate(isPlate ? plainConstraints : plateConstraints)
        NSLayoutConstraint.activate(isPlate ? plateConstraints : plainConstraints)
    }

    private func apply(_ configuration: PointContentConfiguration) {
        applyIconStyle(configuration.iconStyle)
        var content = UIListContentConfiguration.cell()
        switch configuration.iconStyle {
        case .plain:
            content.image = configuration.icon.flatMap { OAUtilities.resize($0, newSize: CGSize(width: PointContentConfiguration.iconSize, height: PointContentConfiguration.iconSize)) }
            plateIconView.image = nil
        case .plate:
            content.directionalLayoutMargins.leading = 0
            plateIconView.image = configuration.icon
        }
        content.text = configuration.title
        content.textProperties.color = configuration.isVisible ? .textColorPrimary : .textColorSecondary
        content.textProperties.font = titleFont(isVisible: configuration.isVisible)
        content.textProperties.numberOfLines = 2
        content.secondaryAttributedText = configuration.secondaryContent?.attributedText()
        content.secondaryTextProperties.color = .textColorSecondary
        content.secondaryTextProperties.numberOfLines = 1
        rowContentView.configuration = content
    }

    private func applySecondaryContent(_ secondaryContent: PointSecondaryContent?) {
        guard var content = rowContentView.configuration as? UIListContentConfiguration else { return }
        content.secondaryAttributedText = secondaryContent?.attributedText()
        rowContentView.configuration = content
    }

    private func titleFont(isVisible: Bool) -> UIFont {
        guard !isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }
}

protocol PrimaryTextLayoutGuideProviding: UIView {
    var primaryTextLayoutGuide: UILayoutGuide? { get }
}

class PointContentTableViewCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        alignSeparatorWithPrimaryText()
    }

    private func alignSeparatorWithPrimaryText() {
        let textLayoutGuide = ([contentView] + contentView.subviews).lazy
            .compactMap { ($0 as? PrimaryTextLayoutGuideProviding)?.primaryTextLayoutGuide }
            .first
        guard let textLayoutGuide, let owningView = textLayoutGuide.owningView else { return }
        contentView.layoutIfNeeded()
        let textFrame = owningView.convert(textLayoutGuide.layoutFrame, to: self)
        guard textFrame.width > 0 else { return }
        let leadingInset = effectiveUserInterfaceLayoutDirection == .rightToLeft ? bounds.width - textFrame.maxX : textFrame.minX
        guard abs(separatorInset.left - leadingInset) > 0.5 else { return }
        separatorInset.left = leadingInset
    }
}
