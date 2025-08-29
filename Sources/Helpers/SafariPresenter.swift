//
//  SafariPresenter.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 19.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

struct SafariPresenter {
    static func present(from viewController: UIViewController, card: AbstractCard) {
        let urlString: String?

        if let wikiCard = card as? WikiImageCard {
            urlString = wikiCard.urlWithCommonAttributions
        } else if let imageCard = card as? UrlImageCard {
            urlString = imageCard.imageUrl
        } else {
            return
        }

        guard let url = URL(string: urlString ?? "") else { return }

        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .iconColorActive
        viewController.present(safariVC, animated: true, completion: nil)
    }
}
