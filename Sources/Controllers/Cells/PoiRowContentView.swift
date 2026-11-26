//
//  PoiRowContentView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import Kingfisher

struct PoiRouteStatistics {
    let length: String
    let uphill: String?
    let downhill: String?
}

struct PoiContentConfiguration: UIContentConfiguration {
    enum Style {
        case compact
        case detailed
        case route

        fileprivate var imageSize: CGFloat {
            switch self {
            case .compact:
                return 42
            case .detailed:
                return 66
            case .route:
                return 36
            }
        }

        fileprivate var iconSize: CGFloat {
            switch self {
            case .compact, .route:
                return 24
            case .detailed:
                return 36
            }
        }
    }

    static let estimatedRowHeight: CGFloat = 76

    fileprivate static let shieldMaxSize = CGSize(width: 72, height: 36)

    let style: Style
    let title: String
    var icon: UIImage?
    var imageURL: URL?
    var secondaryContent: PointSecondaryContent?
    var address: String?
    var openingHours: String?
    var openingHoursColor: UIColor?
    var descriptionText: String?
    var alternateTitle: String?
    var iconTintColor: UIColor?
    var shieldImage: UIImage?
    var routeStatistics: PoiRouteStatistics?
    var secondaryNumberOfLines = 1

    init(style: Style,
         title: String,
         icon: UIImage?,
         imageURL: URL? = nil,
         secondaryContent: PointSecondaryContent?,
         address: String? = nil,
         openingHours: String? = nil,
         openingHoursColor: UIColor? = nil,
         descriptionText: String? = nil,
         alternateTitle: String? = nil,
         iconTintColor: UIColor? = nil,
         shieldImage: UIImage? = nil,
         routeStatistics: PoiRouteStatistics? = nil) {
        self.style = style
        self.title = title
        self.icon = icon
        self.imageURL = imageURL
        self.secondaryContent = secondaryContent
        self.address = address
        self.openingHours = openingHours
        self.openingHoursColor = openingHoursColor
        self.descriptionText = descriptionText
        self.alternateTitle = alternateTitle
        self.iconTintColor = iconTintColor
        self.shieldImage = shieldImage
        self.routeStatistics = routeStatistics
    }

    func makeContentView() -> UIView & UIContentView {
        PoiRowContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> PoiContentConfiguration {
        self
    }
}

private final class PoiRowContentView: UIView, UIContentView, PrimaryTextLayoutGuideProviding {
    private static let verticalInset: CGFloat = 12
    private static let imageSpacing: CGFloat = 12
    private static let imageCornerRadius: CGFloat = 10
    private static let detailsSpacing: CGFloat = 2
    private static let descriptionSpacing: CGFloat = 8
    private static let statisticsSeparator = "  "
    private static let detailsSeparator = " • "

    var configuration: UIContentConfiguration {
        get { appliedConfiguration }
        set {
            guard let configuration = newValue as? PoiContentConfiguration else { return }
            appliedConfiguration = configuration
            apply(configuration)
        }
    }

    var primaryTextLayoutGuide: UILayoutGuide? { textLayoutGuide }

    private let textLayoutGuide = UILayoutGuide()
    private let titleLabel = UILabel()
    private let secondaryLabel = UILabel()
    private let addressLabel = UILabel()
    private let openingHoursIconView = UIImageView()
    private let openingHoursLabel = UILabel()
    private let openingHoursStackView = UIStackView()
    private let detailsStackView = UIStackView()
    private let textStackView = UIStackView()
    private let topStackView = UIStackView()
    private let mainStackView = UIStackView()
    private let descriptionLabel = UILabel()
    private let imageContainerView = UIView()
    private let iconView = UIImageView()
    private let photoView = UIImageView()

    private var imageSizeConstraints: [NSLayoutConstraint] = []
    private var iconSizeConstraints: [NSLayoutConstraint] = []
    private var appliedConfiguration: PoiContentConfiguration
    private var loadedImageURL: URL?

    init(configuration: PoiContentConfiguration) {
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
        secondaryLabel.attributedText = appliedConfiguration.secondaryContent?.attributedText()
        titleLabel.attributedText = Self.titleText(for: appliedConfiguration)
        addressLabel.attributedText = Self.detailsText(for: appliedConfiguration)
    }

    private func setupView() {
        preservesSuperviewLayoutMargins = true
        isAccessibilityElement = true

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontForContentSizeCategory = true

        secondaryLabel.numberOfLines = 1

        addressLabel.font = .preferredFont(forTextStyle: .subheadline)
        addressLabel.textColor = .textColorSecondary
        addressLabel.numberOfLines = 1
        addressLabel.lineBreakMode = .byTruncatingTail
        addressLabel.adjustsFontForContentSizeCategory = true
        addressLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        openingHoursIconView.image = UIImage(systemName: "clock.fill")
        openingHoursIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .small)
        openingHoursIconView.contentMode = .center
        openingHoursIconView.setContentHuggingPriority(.required, for: .horizontal)
        openingHoursIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        openingHoursLabel.font = .preferredFont(forTextStyle: .subheadline)
        openingHoursLabel.numberOfLines = 1
        openingHoursLabel.adjustsFontForContentSizeCategory = true
        openingHoursLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        openingHoursLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        openingHoursStackView.axis = .horizontal
        openingHoursStackView.alignment = .fill
        openingHoursStackView.spacing = 4
        openingHoursStackView.addArrangedSubview(openingHoursIconView)
        openingHoursStackView.addArrangedSubview(openingHoursLabel)
        openingHoursStackView.setContentHuggingPriority(.required, for: .horizontal)
        openingHoursStackView.setContentCompressionResistancePriority(.required, for: .horizontal)

        detailsStackView.axis = .horizontal
        detailsStackView.alignment = .fill
        detailsStackView.spacing = 8
        detailsStackView.addArrangedSubview(addressLabel)
        detailsStackView.addArrangedSubview(openingHoursStackView)

        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(secondaryLabel)
        textStackView.axis = .vertical
        textStackView.alignment = .fill
        textStackView.spacing = Self.detailsSpacing

        imageContainerView.backgroundColor = .imagePlaceholderBg
        imageContainerView.layer.cornerRadius = Self.imageCornerRadius
        imageContainerView.layer.cornerCurve = .continuous
        imageContainerView.clipsToBounds = true
        imageContainerView.setContentHuggingPriority(.required, for: .horizontal)
        imageContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .iconColorSelected
        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.isHidden = true
        [iconView, photoView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            imageContainerView.addSubview($0)
        }

        topStackView.addArrangedSubview(textStackView)
        topStackView.addArrangedSubview(imageContainerView)
        topStackView.axis = .horizontal
        topStackView.alignment = .top
        topStackView.spacing = Self.imageSpacing

        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.numberOfLines = 2
        descriptionLabel.adjustsFontForContentSizeCategory = true

        [topStackView, detailsStackView, descriptionLabel].forEach { mainStackView.addArrangedSubview($0) }
        mainStackView.axis = .vertical
        mainStackView.spacing = Self.descriptionSpacing
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStackView)
        addLayoutGuide(textLayoutGuide)

        imageSizeConstraints = [
            imageContainerView.widthAnchor.constraint(equalToConstant: 0),
            imageContainerView.heightAnchor.constraint(equalToConstant: 0)
        ]
        iconSizeConstraints = [
            iconView.widthAnchor.constraint(equalToConstant: 0),
            iconView.heightAnchor.constraint(equalToConstant: 0)
        ]
        let topContentHuggingConstraints = [textStackView, imageContainerView].map {
            let constraint = topStackView.bottomAnchor.constraint(equalTo: $0.bottomAnchor)
            constraint.priority = .defaultLow
            return constraint
        }
        NSLayoutConstraint.activate(imageSizeConstraints + iconSizeConstraints + topContentHuggingConstraints + [
            textLayoutGuide.topAnchor.constraint(equalTo: textStackView.topAnchor),
            textLayoutGuide.leadingAnchor.constraint(equalTo: textStackView.leadingAnchor),
            textLayoutGuide.trailingAnchor.constraint(equalTo: textStackView.trailingAnchor),
            textLayoutGuide.bottomAnchor.constraint(equalTo: textStackView.bottomAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor, constant: Self.verticalInset),
            mainStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.verticalInset),
            iconView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
            photoView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            photoView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            photoView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            photoView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor)
        ])
    }

    private func apply(_ configuration: PoiContentConfiguration) {
        titleLabel.attributedText = Self.titleText(for: configuration)
        secondaryLabel.attributedText = configuration.secondaryContent?.attributedText()
        secondaryLabel.numberOfLines = configuration.secondaryNumberOfLines
        secondaryLabel.isHidden = secondaryLabel.attributedText == nil

        let address = configuration.address ?? ""
        let detailsText = Self.detailsText(for: configuration)
        addressLabel.attributedText = detailsText
        addressLabel.isHidden = detailsText == nil
        let openingHours = configuration.openingHours ?? ""
        openingHoursLabel.text = openingHours
        openingHoursLabel.textColor = configuration.openingHoursColor ?? .textColorSecondary
        openingHoursIconView.tintColor = configuration.openingHoursColor ?? .textColorSecondary
        openingHoursStackView.isHidden = openingHours.isEmpty
        detailsStackView.isHidden = detailsText == nil && openingHours.isEmpty
        placeDetails(for: configuration.style)
        let detailsBelowTopContent = configuration.style != .detailed && !detailsStackView.isHidden
        mainStackView.setCustomSpacing(detailsBelowTopContent ? Self.detailsSpacing : Self.descriptionSpacing, after: topStackView)

        let descriptionText = configuration.style == .detailed ? configuration.descriptionText ?? "" : ""
        descriptionLabel.text = descriptionText
        descriptionLabel.isHidden = descriptionText.isEmpty

        applyIcon(configuration)
        applyImage(configuration.imageURL, style: configuration.style)

        let statistics = configuration.routeStatistics
        accessibilityLabel = [configuration.title,
                              configuration.alternateTitle,
                              configuration.secondaryContent?.formattedDistance,
                              configuration.secondaryContent?.trailingText,
                              statistics?.length,
                              statistics?.uphill,
                              statistics?.downhill,
                              address,
                              openingHours,
                              descriptionText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private func placeDetails(for style: PoiContentConfiguration.Style) {
        let container = style == .detailed ? textStackView : mainStackView
        guard detailsStackView.superview !== container else { return }
        detailsStackView.removeFromSuperview()
        switch style {
        case .compact, .route:
            mainStackView.insertArrangedSubview(detailsStackView, at: 1)
        case .detailed:
            textStackView.addArrangedSubview(detailsStackView)
        }
    }

    private func applyIcon(_ configuration: PoiContentConfiguration) {
        if let shieldImage = configuration.shieldImage {
            let maxSize = PoiContentConfiguration.shieldMaxSize
            let size = Self.fittedSize(shieldImage.size, in: maxSize)
            setImageContainerSize(CGSize(width: size.width, height: maxSize.height), iconSize: size)
            imageContainerView.backgroundColor = .clear
            imageContainerView.layer.cornerRadius = 0
            iconView.image = shieldImage.withRenderingMode(.alwaysOriginal)
        } else {
            let imageSize = configuration.style.imageSize
            let iconSize = configuration.style.iconSize
            setImageContainerSize(CGSize(width: imageSize, height: imageSize), iconSize: CGSize(width: iconSize, height: iconSize))
            imageContainerView.backgroundColor = .imagePlaceholderBg
            imageContainerView.layer.cornerRadius = Self.imageCornerRadius
            iconView.image = configuration.icon?.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = configuration.iconTintColor ?? .iconColorSelected
        }
    }

    private func setImageContainerSize(_ size: CGSize, iconSize: CGSize) {
        imageSizeConstraints[0].constant = size.width
        imageSizeConstraints[1].constant = size.height
        iconSizeConstraints[0].constant = iconSize.width
        iconSizeConstraints[1].constant = iconSize.height
    }

    private static func fittedSize(_ size: CGSize, in maxSize: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return .zero }
        let scale = min(maxSize.width / size.width, maxSize.height / size.height)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private static func titleText(for configuration: PoiContentConfiguration) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = NSMutableAttributedString(string: configuration.title, attributes: [.font: font, .foregroundColor: UIColor.textColorPrimary])
        if let alternateTitle = configuration.alternateTitle, !alternateTitle.isEmpty, alternateTitle != configuration.title {
            text.append(NSAttributedString(string: " (\(alternateTitle))", attributes: [.font: font, .foregroundColor: UIColor.textColorSecondary]))
        }
        return text
    }

    private static func detailsText(for configuration: PoiContentConfiguration) -> NSAttributedString? {
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .subheadline), .foregroundColor: UIColor.textColorSecondary]
        let text = NSMutableAttributedString()
        if let statistics = configuration.routeStatistics {
            appendStatistic(statistics.length, symbolName: "arrow.left.and.right", to: text, attributes: attributes)
            appendStatistic(statistics.uphill, symbolName: "arrow.up.right", to: text, attributes: attributes)
            appendStatistic(statistics.downhill, symbolName: "arrow.down.right", to: text, attributes: attributes)
        }
        if let address = configuration.address, !address.isEmpty {
            if text.length > 0 {
                text.append(NSAttributedString(string: detailsSeparator, attributes: attributes))
            }
            text.append(NSAttributedString(string: address, attributes: attributes))
        }
        return text.length > 0 ? text : nil
    }

    private static func appendStatistic(_ value: String?, symbolName: String, to text: NSMutableAttributedString, attributes: [NSAttributedString.Key: Any]) {
        guard let value, !value.isEmpty else { return }
        if text.length > 0 {
            text.append(NSAttributedString(string: statisticsSeparator, attributes: attributes))
        }
        let configuration = UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .small)
        if let symbol = UIImage(systemName: symbolName, withConfiguration: configuration)?.withRenderingMode(.alwaysTemplate) {
            let symbolText = NSMutableAttributedString(attachment: NSTextAttachment(image: symbol))
            symbolText.addAttributes(attributes, range: NSRange(location: 0, length: symbolText.length))
            text.append(symbolText)
            text.append(NSAttributedString(string: " ", attributes: attributes))
        }
        text.append(NSAttributedString(string: value, attributes: attributes))
    }

    private func applyImage(_ url: URL?, style: PoiContentConfiguration.Style) {
        guard url != loadedImageURL else { return }
        photoView.kf.cancelDownloadTask()
        photoView.image = nil
        photoView.isHidden = true
        iconView.isHidden = false
        loadedImageURL = url
        guard let url else { return }

        let size = CGSize(width: style.imageSize, height: style.imageSize)
        photoView.kf.setImage(
            with: url,
            options: [
                .targetCache(.onlinePhotoAndMapillaryDefaultCache),
                .requestModifier(ImageDownloadRequestModifier()),
                .processor(DownsamplingImageProcessor(size: size)),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ]) { [weak self] result in
                guard let self, self.loadedImageURL == url, case .success = result else { return }
                self.photoView.isHidden = false
                self.iconView.isHidden = true
            }
    }
}

final class PoiContentTableViewCell: PointContentTableViewCell {}
