//
//  GetElevationDataViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 25.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class GetElevationDataViewController: UIViewController {

    var onSelectMethod: ((Bool) -> Void)?

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let separatorView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = .viewBg

        let closeButton = PlanRouteButtonFactory.iconButton(image: .templateImageNamed("ic_navbar_close"), size: 44)
        closeButton.layer.shadowOpacity = 0
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        view.addSubview(closeButton)

        titleLabel.text = localizedString("get_elevation_data")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .textColorPrimary
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        descriptionLabel.text = localizedString("get_elevation_data_description")
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.textAlignment = .left
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)

        let optionsCard = UIView()
        optionsCard.backgroundColor = .groupBg
        optionsCard.layer.cornerRadius = 24
        optionsCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optionsCard)

        let nearbyRoadsRow = makeOptionRow(
            icon: .templateImageNamed("ic_custom_attach_track"),
            title: localizedString("use_nearby_roads"),
            subtitle: localizedString("may_adjust_track_geometry"),
            useNearbyRoads: true
        )

        separatorView.backgroundColor = .customSeparator
        separatorView.translatesAutoresizingMaskIntoConstraints = false

        let terrainRow = makeOptionRow(
            icon: .templateImageNamed("ic_custom_terrain"),
            title: localizedString("use_terrain_maps"),
            subtitle: localizedString("track_geometry_stays_unchanged"),
            useNearbyRoads: false
        )

        [nearbyRoadsRow, separatorView, terrainRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            optionsCard.addSubview($0)
        }

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            descriptionLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            optionsCard.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            optionsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            optionsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            nearbyRoadsRow.topAnchor.constraint(equalTo: optionsCard.topAnchor),
            nearbyRoadsRow.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor),
            nearbyRoadsRow.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor),

            separatorView.topAnchor.constraint(equalTo: nearbyRoadsRow.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor, constant: 56),
            separatorView.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor, constant: -16),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            terrainRow.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            terrainRow.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor),
            terrainRow.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor),
            terrainRow.bottomAnchor.constraint(equalTo: optionsCard.bottomAnchor)
        ])
    }

    private func makeOptionRow(icon: UIImage?, title: String, subtitle: String, useNearbyRoads: Bool) -> UIView {
        let row = UIView()

        let iconView = UIImageView(image: icon)
        iconView.tintColor = .iconColorActive
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.textColor = .textColorPrimary

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .textColorSecondary

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        [iconView, textStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -12)
        ])

        let tapButton = UIButton(type: .custom)
        tapButton.addTarget(self, action: useNearbyRoads ? #selector(onNearbyRoads) : #selector(onTerrainMaps), for: .touchUpInside)
        tapButton.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(tapButton)

        NSLayoutConstraint.activate([
            tapButton.topAnchor.constraint(equalTo: row.topAnchor),
            tapButton.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            tapButton.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

    @objc private func onNearbyRoads() {
        dismiss(animated: true) { [weak self] in
            self?.onSelectMethod?(true)
        }
    }

    @objc private func onTerrainMaps() {
        dismiss(animated: true) { [weak self] in
            self?.onSelectMethod?(false)
        }
    }
}
