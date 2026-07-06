//
//  AstroGalleryCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroGalleryCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroGalleryCardViewHolder {
    static func makeView(item: AstroGalleryCardItem,
                         presentingController: UIViewController,
                         onUpdateImage: @escaping () -> Void,
                         onToggle: @escaping (String) -> Void) -> UIView {
        AstroGalleryCardView(item: item,
                             presentingController: presentingController,
                             onUpdateImage: onUpdateImage,
                             onToggle: onToggle)
    }
}

private final class AstroGalleryCardView: UIView {
    private let item: AstroGalleryCardItem
    
    private let onUpdateImage: () -> Void
    private let onToggle: (String) -> Void

    private let stack = UIStackView()
    private let headerButton = UIControl()
    private let iconView = UIImageView(image: .icCustomPhoto)
    private let titleLabel = UILabel()
    private let arrowView = UIImageView()
    private var galleryHeightConstraint: NSLayoutConstraint?
    
    private weak var presentingController: UIViewController?

    init(item: AstroGalleryCardItem,
         presentingController: UIViewController,
         onUpdateImage: @escaping () -> Void,
         onToggle: @escaping (String) -> Void) {
        self.item = item
        self.presentingController = presentingController
        self.onUpdateImage = onUpdateImage
        self.onToggle = onToggle
        super.init(frame: .zero)
        setupView()
        applyState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
            applyTheme()
        }
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 26
        layer.masksToBounds = true

        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        setupHeader()
        stack.addArrangedSubview(headerButton)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        applyTheme()
    }

    private func setupHeader() {
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        headerButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        headerButton.addAction(UIAction { [weak self] _ in
            guard let self else {
                return
            }
            onToggle(item.wid)
        }, for: .touchUpInside)

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = localizedString("online_photos")
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowView.contentMode = .scaleAspectFit
        arrowView.translatesAutoresizingMaskIntoConstraints = false

        let arrowContainer = UIView()
        arrowContainer.translatesAutoresizingMaskIntoConstraints = false
        arrowContainer.isUserInteractionEnabled = false

        [iconView, titleLabel, arrowContainer].forEach(headerButton.addSubview)
        arrowContainer.addSubview(arrowView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: headerButton.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: headerButton.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: headerButton.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: arrowContainer.leadingAnchor, constant: -16),

            arrowContainer.trailingAnchor.constraint(equalTo: headerButton.trailingAnchor, constant: -1),
            arrowContainer.centerYAnchor.constraint(equalTo: headerButton.centerYAnchor),
            arrowContainer.widthAnchor.constraint(equalToConstant: 48),
            arrowContainer.heightAnchor.constraint(equalToConstant: 48),

            arrowView.centerXAnchor.constraint(equalTo: arrowContainer.centerXAnchor),
            arrowView.centerYAnchor.constraint(equalTo: arrowContainer.centerYAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 30),
            arrowView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func applyState() {
        let arrowName: String
        switch item.state {
        case .collapsed:
            arrowName = "ic_custom_arrow_right"
        case .loading, .ready:
            arrowName = "ic_custom_arrow_down"
        }
        arrowView.image = AstroIcon.template(arrowName)

        switch item.state {
        case .collapsed:
            break
        case .loading:
            stack.addArrangedSubview(AstroIndeterminateProgressLine())
        case .ready(let cards):
            stack.addArrangedSubview(makeContent(cards: cards))
        }
    }

    private func makeContent(cards: [AbstractCard]) -> UIView {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStack)

        let preparedCards = cards.map { card -> AbstractCard in
            if let noInternetCard = card as? NoInternetCard {
                noInternetCard.onTryAgainAction = onUpdateImage
            }
            return card
        }

        let cardsViewController = CardsViewController(frame: .zero)
        cardsViewController.translatesAutoresizingMaskIntoConstraints = false
        cardsViewController.contentType = .onlinePhoto
        cardsViewController.title = item.showAllTitle ?? ""
        cardsViewController.carouselPresenter = presentingController
        cardsViewController.didChangeHeightAction = { [weak self] _, height in
            self?.galleryHeightConstraint?.constant = CGFloat(height)
        }
        contentStack.addArrangedSubview(cardsViewController)

        galleryHeightConstraint = cardsViewController.heightAnchor.constraint(equalToConstant: 156)
        galleryHeightConstraint?.isActive = true
        cardsViewController.setCardsFilter(CardsFilter(cards: preparedCards))

        let imageCards = preparedCards.compactMap { $0 as? ImageCard }
        if !imageCards.isEmpty {
            contentStack.addArrangedSubview(makeShowAllButton(cards: imageCards))
        }

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        return contentView
    }

    private func makeShowAllButton(cards: [ImageCard]) -> UIView {
        var config = UIButton.Configuration.filled()
        config.title = localizedString("shared_string_show_all")
        config.baseBackgroundColor = .buttonBgColorTertiary
        config.baseForegroundColor = .buttonTextColorSecondary
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            self?.openGalleryGrid(cards: cards)
        }, for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.addSubview(button)
        container.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            button.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        return container
    }

    private func openGalleryGrid(cards: [ImageCard]) {
        guard let presentingController else {
            return
        }
        let controller = GalleryGridViewController()
        controller.cards = cards.map { $0 as AbstractCard }
        controller.titleString = item.showAllTitle ?? ""
        controller.presentsCarouselFromSelf = true

        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        presentingController.present(navigationController, animated: true)
    }

    private func applyTheme() {
        backgroundColor = AstroContextMenuTheme.cardBackground
        iconView.tintColor = AstroContextMenuTheme.defaultIcon
        arrowView.tintColor = AstroContextMenuTheme.activeIcon
        titleLabel.textColor = AstroContextMenuTheme.primaryText
    }
}

private final class AstroIndeterminateProgressLine: UIView {
    private let progressView = UIProgressView(progressViewStyle: .bar)

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            progressView.layer.removeAllAnimations()
        } else {
            startAnimating()
        }
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 2).isActive = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = AstroContextMenuTheme.separator.withAlphaComponent(0.25)
        progressView.progressTintColor = AstroContextMenuTheme.primaryButton
        addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressView.topAnchor.constraint(equalTo: topAnchor),
            progressView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func startAnimating() {
        progressView.setProgress(0.0, animated: false)
        UIView.animate(withDuration: 0.9,
                       delay: 0,
                       options: [.repeat, .autoreverse, .curveEaseInOut]) { [progressView] in
            progressView.setProgress(1.0, animated: true)
        }
    }
}
