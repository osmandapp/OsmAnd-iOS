//
//  SkyObjectInfoBottomSheet.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import OsmAndShared
import UIKit

final class SkyObjectInfoFragment: UIViewController {
    private let object: SkyObject
    private let date: Date
    private let observer: Observer
    private let dataProvider: AstroDataProvider?
    private let preferredLocale: String?
    private var articleUrl: String?

    var onClose: (() -> Void)?

    init(object: SkyObject,
         date: Date,
         observer: Observer,
         dataProvider: AstroDataProvider?,
         preferredLocale: String?) {
        self.object = object
        self.date = date
        self.observer = observer
        self.dataProvider = dataProvider
        self.preferredLocale = preferredLocale
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.03, alpha: 0.96)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor(white: 0.8, alpha: 1)
        closeButton.backgroundColor = UIColor(white: 0.12, alpha: 1)
        closeButton.layer.cornerRadius = 16
        closeButton.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)

        let headerStack = UIStackView()
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .vertical
        headerStack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = object.niceName()
        titleLabel.textColor = .white
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 2

        let typeLabel = UILabel()
        typeLabel.text = object.type.localizedName
        typeLabel.textColor = UIColor(white: 0.72, alpha: 1)
        typeLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)

        headerStack.addArrangedSubview(titleLabel)
        headerStack.addArrangedSubview(typeLabel)

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 10

        view.addSubview(closeButton)
        view.addSubview(headerStack)
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        populate(stack)

        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerStack.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            headerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func populate(_ stack: UIStackView) {
        refreshObjectPosition()

        stack.addArrangedSubview(infoLabel("\(label("shared_string_azimuth", fallback: "Azimuth")): \(formatDegrees(object.azimuth))  \(label("altitude", fallback: "Altitude")): \(formatDegrees(object.altitude))"))
        stack.addArrangedSubview(infoLabel("RA: \(formatHours(object.ra))  Dec: \(formatDegrees(object.dec))"))
        stack.addArrangedSubview(infoLabel("\(label("shared_string_magnitude", fallback: "Magnitude")): \(formatNumber(object.magnitude, digits: 2))"))

        if let distanceText = distanceText() {
            stack.addArrangedSubview(infoLabel("\(label("distance", fallback: "Distance")): \(distanceText)"))
        }

        if let riseSet = riseSetText() {
            if let rise = riseSet.rise {
                stack.addArrangedSubview(infoLabel("\(label("astro_rise", fallback: "Rise")): \(rise)"))
            }
            if let set = riseSet.set {
                stack.addArrangedSubview(infoLabel("\(label("astro_set", fallback: "Set")): \(set)"))
            }
        }

        if let radius = object.radius, radius.isFinite, radius > 0 {
            stack.addArrangedSubview(infoLabel("Radius: \(formatNumber(radius, digits: 2))"))
        }
        if let mass = object.mass, mass.isFinite, mass > 0 {
            stack.addArrangedSubview(infoLabel("Mass: \(formatNumber(mass, digits: 2))"))
        }

        if let article = article(), !article.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            articleUrl = article.getOnlineArticleUrl()
            stack.addArrangedSubview(sectionTitle(label("shared_string_description", fallback: "Description")))
            stack.addArrangedSubview(descriptionLabel(article.description.trimmingCharacters(in: .whitespacesAndNewlines)))
        } else if !object.wid.isEmpty {
            articleUrl = "https://www.wikidata.org/wiki/\(object.wid)"
        }

        if articleUrl != nil {
            stack.addArrangedSubview(articleButton())
        }
    }

    private func infoLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(white: 0.88, alpha: 1)
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 0
        return label
    }

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.numberOfLines = 0
        return label
    }

    private func descriptionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(white: 0.82, alpha: 1)
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.numberOfLines = 6
        return label
    }

    private func articleButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = label("context_menu_read_full_article", fallback: "Read full article")
        config.image = UIImage(systemName: "safari")
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        button.contentHorizontalAlignment = .leading
        button.addAction(UIAction { [weak self] _ in
            self?.openArticle()
        }, for: .touchUpInside)
        return button
    }

    private func article() -> AstroArticle? {
        guard !object.wid.isEmpty else {
            return nil
        }
        return dataProvider?.getAstroArticle(wikidataId: object.wid, lang: preferredLocale)
    }

    private func refreshObjectPosition() {
        if let horizontal = AstroUtils.horizontalPosition(for: object,
                                                          time: AstroUtils.astronomyTime(from: date),
                                                          observer: observer) {
            object.azimuth = horizontal.azimuth
            object.altitude = horizontal.altitude
        }
    }

    private func distanceText() -> String? {
        if object.type.isSunSystem(), object.distAu.isFinite, object.distAu > 0 {
            return "\(formatNumber(object.distAu, digits: 3)) AU"
        }
        guard let distance = object.distance, distance.isFinite, distance > 0 else {
            return nil
        }
        if distance >= 1_000_000 {
            return "\(formatNumber(distance / 1_000_000, digits: 2)) Mly"
        }
        if distance >= 1_000 {
            return "\(formatNumber(distance / 1_000, digits: 2)) kly"
        }
        return "\(formatNumber(distance, digits: 2)) ly"
    }

    private func riseSetText() -> (rise: String?, set: String?)? {
        guard let riseSet = calculateRiseSet(),
              riseSet.rise != nil || riseSet.set != nil else {
            return nil
        }
        return (riseSet.rise.map(formatTime), riseSet.set.map(formatTime))
    }

    private func calculateRiseSet() -> (rise: Date?, set: Date?)? {
        guard let body = bodyForRiseSet() else {
            return nil
        }

        let searchStart = AstroUtils.astronomyTime(from: Calendar.current.startOfDay(for: date))
        let riseTime = AstronomyKt.searchRiseSet(body: body,
                                                 observer: observer,
                                                 direction: Direction.rise,
                                                 startTime: searchStart,
                                                 limitDays: 1.2,
                                                 metersAboveGround: 0.0)
        let setTime = AstronomyKt.searchRiseSet(body: body,
                                                observer: observer,
                                                direction: Direction.set,
                                                startTime: searchStart,
                                                limitDays: 1.2,
                                                metersAboveGround: 0.0)
        return (date(from: riseTime), date(from: setTime))
    }

    private func bodyForRiseSet() -> Body? {
        if let body = object.body {
            return body
        }
        guard !object.type.isSunSystem() else {
            return nil
        }
        AstronomyKt.defineStar(body: Body.star2, ra: object.ra, dec: object.dec, distanceLightYears: 1000.0)
        return Body.star2
    }

    private func date(from time: Time?) -> Date? {
        guard let time else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(time.toMillisecondsSince1970()) / 1000.0)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }

    private func formatDegrees(_ value: Double) -> String {
        "\(formatNumber(value, digits: 1)) deg"
    }

    private func formatHours(_ value: Double) -> String {
        "\(formatNumber(value, digits: 3)) h"
    }

    private func formatNumber(_ value: Double, digits: Int) -> String {
        String(format: "%.\(digits)f", value)
    }

    private func label(_ key: String, fallback: String) -> String {
        let value = localizedString(key)
        return value == key ? fallback : value
    }

    private func openArticle() {
        guard let articleUrl, let url = URL(string: articleUrl) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
