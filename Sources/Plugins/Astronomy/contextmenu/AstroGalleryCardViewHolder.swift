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
        let card = AstroCardContainerView(title: localizedString("online_photos"),
                                          iconName: "ic_action_photo")
        let toggleButton = UIButton(type: .system)
        toggleButton.contentHorizontalAlignment = .leading
        toggleButton.tintColor = AstroContextMenuTheme.activeIcon
        toggleButton.setTitleColor(AstroContextMenuTheme.activeText, for: .normal)
        toggleButton.setTitle(toggleTitle(for: item.state), for: .normal)
        toggleButton.setImage(AstroIcon.template(toggleIconName(for: item.state)), for: .normal)
        toggleButton.addAction(UIAction { _ in onToggle(item.wid) }, for: .touchUpInside)
        card.stack.addArrangedSubview(toggleButton)

        switch item.state {
        case .collapsed:
            break
        case .loading:
            let progress = UIActivityIndicatorView(style: .medium)
            progress.startAnimating()
            card.stack.addArrangedSubview(progress)
        case .ready(let cards):
            if cards.isEmpty {
                let emptyLabel = UILabel()
                emptyLabel.text = localizedString("no_photos_available")
                emptyLabel.textColor = AstroContextMenuTheme.secondaryText
                emptyLabel.font = .systemFont(ofSize: 14)
                card.stack.addArrangedSubview(emptyLabel)
            } else {
                let gallery = horizontalGallery(cards: cards, presentingController: presentingController)
                card.stack.addArrangedSubview(gallery)
                let showAll = UIButton(type: .system)
                showAll.setTitle(localizedString("shared_string_show_all"), for: .normal)
                showAll.tintColor = AstroContextMenuTheme.activeIcon
                showAll.setTitleColor(AstroContextMenuTheme.activeText, for: .normal)
                showAll.addAction(UIAction { _ in
                    let controller = GalleryGridViewController()
                    controller.cards = cards
                    controller.titleString = item.showAllTitle ?? ""
                    presentingController.showMediumSheetViewController(viewController: controller, isLargeAvailable: true)
                }, for: .touchUpInside)
                card.stack.addArrangedSubview(showAll)
            }
        }
        return card
    }

    private static func horizontalGallery(cards: [AbstractCard], presentingController: UIViewController) -> UIView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.heightAnchor.constraint(equalToConstant: 112).isActive = true

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        cards.prefix(10).forEach { card in
            let thumbnail = AstroGalleryThumbnailView(card: card)
            thumbnail.addAction {
                let controller = GalleryGridViewController()
                controller.cards = cards
                controller.titleString = ""
                presentingController.showMediumSheetViewController(viewController: controller, isLargeAvailable: true)
            }
            stack.addArrangedSubview(thumbnail)
        }
        return scrollView
    }

    private static func toggleTitle(for state: AstroGalleryState) -> String {
        switch state {
        case .collapsed:
            return localizedString("shared_string_show")
        case .loading:
            return localizedString("shared_string_loading")
        case .ready:
            return localizedString("shared_string_collapse")
        }
    }

    private static func toggleIconName(for state: AstroGalleryState) -> String {
        switch state {
        case .collapsed:
            return "ic_action_arrow_down"
        case .loading:
            return "ic_action_time"
        case .ready:
            return "ic_action_arrow_up"
        }
    }
}

private final class AstroGalleryThumbnailView: UIControl {
    private let imageView = UIImageView()
    private var task: URLSessionDataTask?

    init(card: AbstractCard) {
        super.init(frame: .zero)
        setup(card: card)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        task?.cancel()
    }

    func addAction(_ action: @escaping () -> Void) {
        addAction(UIAction { _ in action() }, for: .touchUpInside)
    }

    private func setup(card: AbstractCard) {
        widthAnchor.constraint(equalToConstant: 112).isActive = true
        heightAnchor.constraint(equalToConstant: 112).isActive = true
        backgroundColor = UIColor(named: "imagePlaceholderBgColor") ?? AstroContextMenuTheme.secondaryBackground
        layer.cornerRadius = 7
        clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        guard let imageCard = card as? ImageCard,
              let url = URL(string: imageCard.imageUrl) else {
            imageView.image = AstroIcon.template("ic_action_photo")
            imageView.tintColor = AstroContextMenuTheme.secondaryIcon
            return
        }
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data,
                  let image = UIImage(data: data) else {
                return
            }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
        task?.resume()
    }
}
