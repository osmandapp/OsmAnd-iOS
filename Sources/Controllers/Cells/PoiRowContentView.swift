//
//  PoiRowContentView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import Kingfisher

struct PoiContentConfiguration: UIContentConfiguration {
    enum Style {
        case compact
        case detailed

        fileprivate var imageSize: CGFloat {
            switch self {
            case .compact:
                return 42
            case .detailed:
                return 66
            }
        }

        fileprivate var iconSize: CGFloat {
            switch self {
            case .compact:
                return 24
            case .detailed:
                return 36
            }
        }
    }

    static let estimatedRowHeight: CGFloat = 76

    let style: Style
    let title: String
    var icon: UIImage?
    var imageURL: URL?
    var secondaryContent: PointSecondaryContent?
    var address: String?
    var openingHours: String?
    var openingHoursColor: UIColor?
    var descriptionText: String?

    init(style: Style,
         title: String,
         icon: UIImage?,
         imageURL: URL? = nil,
         secondaryContent: PointSecondaryContent?,
         address: String? = nil,
         openingHours: String? = nil,
         openingHoursColor: UIColor? = nil,
         descriptionText: String? = nil) {
        self.style = style
        self.title = title
        self.icon = icon
        self.imageURL = imageURL
        self.secondaryContent = secondaryContent
        self.address = address
        self.openingHours = openingHours
        self.openingHoursColor = openingHoursColor
        self.descriptionText = descriptionText
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

        let textStackView = UIStackView(arrangedSubviews: [titleLabel, secondaryLabel])
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
        titleLabel.text = configuration.title
        secondaryLabel.attributedText = configuration.secondaryContent?.attributedText()
        secondaryLabel.isHidden = secondaryLabel.attributedText == nil

        let address = configuration.address ?? ""
        addressLabel.text = address
        addressLabel.isHidden = address.isEmpty
        let openingHours = configuration.openingHours ?? ""
        openingHoursLabel.text = openingHours
        openingHoursLabel.textColor = configuration.openingHoursColor ?? .textColorSecondary
        openingHoursIconView.tintColor = configuration.openingHoursColor ?? .textColorSecondary
        openingHoursStackView.isHidden = openingHours.isEmpty
        detailsStackView.isHidden = address.isEmpty && openingHours.isEmpty
        mainStackView.setCustomSpacing(detailsStackView.isHidden ? Self.descriptionSpacing : Self.detailsSpacing, after: topStackView)

        let descriptionText = configuration.style == .detailed ? configuration.descriptionText ?? "" : ""
        descriptionLabel.text = descriptionText
        descriptionLabel.isHidden = descriptionText.isEmpty

        imageSizeConstraints.forEach { $0.constant = configuration.style.imageSize }
        iconSizeConstraints.forEach { $0.constant = configuration.style.iconSize }
        iconView.image = configuration.icon?.withRenderingMode(.alwaysTemplate)
        applyImage(configuration.imageURL, style: configuration.style)

        accessibilityLabel = [configuration.title,
                              configuration.secondaryContent?.formattedDistance,
                              configuration.secondaryContent?.trailingText,
                              address,
                              openingHours,
                              descriptionText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
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
