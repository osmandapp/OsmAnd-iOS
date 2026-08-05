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
    let address: String?
    let date: String?
    let trailingText: String?
    let isDateFirst: Bool

    init(formattedDistance: String?, direction: CGFloat, address: String?, date: String?, trailingText: String? = nil, isDateFirst: Bool = false) {
        self.formattedDistance = formattedDistance
        self.direction = direction
        self.address = address
        self.date = date
        self.trailingText = trailingText
        self.isDateFirst = isDateFirst
    }

    private func append(_ text: String?, to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard let text, !text.isEmpty else { return }
        appendSeparatorIfNeeded(to: result, attributes: attributes)
        result.append(NSAttributedString(string: text, attributes: attributes))
    }

    private func appendDistance(to result: NSMutableAttributedString, font: UIFont, directionAttributes: [NSAttributedString.Key: Any], separatorAttributes: [NSAttributedString.Key: Any]) {
        guard let formattedDistance, !formattedDistance.isEmpty else { return }
        appendSeparatorIfNeeded(to: result, attributes: separatorAttributes)
        if let directionIcon = directionIcon(font: font) {
            result.append(directionIcon)
        }

        result.append(NSAttributedString(string: formattedDistance, attributes: directionAttributes))
    }

    private func appendSeparatorIfNeeded(to result: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard result.length > 0 else { return }
        result.append(NSAttributedString(string: " • ", attributes: attributes))
    }

    private func directionIcon(font: UIFont) -> NSAttributedString? {
        let size = UIFontMetrics.default.scaledValue(for: PointContentConfiguration.directionIconSize)
        guard let image = OAUtilities.resize(.icSmallDirection, newSize: CGSize(width: size, height: size))?.withTintColor(.iconColorDirectionActive) else { return nil }
        let rotatedImage = image.rotatedWithinBounds(by: direction)
        let attachment = NSTextAttachment()
        attachment.image = rotatedImage
        attachment.bounds = CGRect(x: 0, y: (font.capHeight - rotatedImage.size.height) / 2, width: rotatedImage.size.width, height: rotatedImage.size.height)
        return NSAttributedString(attachment: attachment)
    }

    fileprivate func attributedText() -> NSAttributedString? {
        let font = UIFont.scaledSystemFont(ofSize: PointContentConfiguration.secondaryTextSize)
        let directionAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.textColorDirectionActive]
        let secondaryAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.textColorSecondary]
        let result = NSMutableAttributedString()
        if isDateFirst {
            append(date, to: result, attributes: secondaryAttributes)
            appendDistance(to: result, font: font, directionAttributes: directionAttributes, separatorAttributes: secondaryAttributes)
            append(address, to: result, attributes: secondaryAttributes)
        } else {
            appendDistance(to: result, font: font, directionAttributes: directionAttributes, separatorAttributes: secondaryAttributes)
            append(address, to: result, attributes: secondaryAttributes)
            append(date, to: result, attributes: secondaryAttributes)
        }

        append(trailingText, to: result, attributes: secondaryAttributes)
        return result.length > 0 ? result : nil
    }
}

struct PointContentConfiguration: UIContentConfiguration {
    static let estimatedRowHeight: CGFloat = 66

    fileprivate static let iconSize: CGFloat = 36
    fileprivate static let directionIconSize: CGFloat = 18
    fileprivate static let secondaryTextSize: CGFloat = 15

    let icon: UIImage?
    let title: String
    let isVisible: Bool

    var secondaryContent: PointSecondaryContent?

    init(icon: UIImage?, title: String, isVisible: Bool = true, secondaryContent: PointSecondaryContent?) {
        self.icon = icon
        self.title = title
        self.isVisible = isVisible
        self.secondaryContent = secondaryContent
    }

    static func backgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listGroupedCell()
        configuration.backgroundColor = .groupBg
        return configuration
    }

    func makeContentView() -> UIView & UIContentView {
        PointRowContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PointContentConfiguration {
        self
    }
}

private final class PointRowContentView: UIView, UIContentView {
    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let configuration = newValue as? PointContentConfiguration else { return }
            let hasSamePrimaryContent = appliedConfiguration.icon === configuration.icon && appliedConfiguration.title == configuration.title && appliedConfiguration.isVisible == configuration.isVisible
            appliedConfiguration = configuration
            if hasSamePrimaryContent {
                applySecondaryContent(configuration.secondaryContent)
            } else {
                apply(configuration)
            }
        }
    }

    private let rowContentView = UIListContentView(configuration: .cell())

    private var appliedConfiguration: PointContentConfiguration

    init(configuration: PointContentConfiguration) {
        appliedConfiguration = configuration
        super.init(frame: .zero)
        setupView()
        apply(configuration)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory else { return }
        apply(appliedConfiguration)
    }

    private func setupView() {
        rowContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowContentView)
        NSLayoutConstraint.activate([
            rowContentView.topAnchor.constraint(equalTo: topAnchor),
            rowContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func apply(_ configuration: PointContentConfiguration) {
        var content = UIListContentConfiguration.cell()
        content.image = configuration.icon.flatMap { OAUtilities.resize($0, newSize: CGSize(width: PointContentConfiguration.iconSize, height: PointContentConfiguration.iconSize)) }
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
