//
//  PlanRouteRouteViewController.swift
//  OsmAnd Maps
//
//  Created by OsmAnd on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteRouteViewController: UIViewController, PlanRouteTabContent {
    let planRouteTab: PlanRouteTab = .route

    private weak var dataSource: PlanRoutePointsDataSource?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var points: [PlanRoutePoint] = []

    init(dataSource: PlanRoutePointsDataSource?) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        reloadData()
    }

    func reloadData() {
        guard isViewLoaded else { return }
        points = dataSource?.routePoints ?? []
        tableView.reloadData()
    }

    private func setupTableView() {
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 72, right: 0)
        tableView.register(PlanRoutePointCell.self, forCellReuseIdentifier: PlanRoutePointCell.cellReuseId)
        tableView.register(PlanRouteEmptyCell.self, forCellReuseIdentifier: PlanRouteEmptyCell.cellReuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource
extension PlanRouteRouteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        points.isEmpty ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? max(points.count, 1) : 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? localizedString("route_points") : nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, points.isEmpty {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRouteEmptyCell.cellReuseId, for: indexPath) as? PlanRouteEmptyCell else {
                return UITableViewCell()
            }
            return cell
        }
        if indexPath.section == 1 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = localizedString("gpx_start_new_segment")
            cell.textLabel?.textColor = .iconColorActive
            cell.textLabel?.font = .scaledSystemFont(ofSize: 17)
            cell.backgroundColor = .groupBg
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanRoutePointCell.cellReuseId, for: indexPath) as? PlanRoutePointCell else {
            return UITableViewCell()
        }
        cell.configure(with: points[indexPath.row])
        cell.onDelete = { [weak self] in
            print("[PlanRoute] Delete point at index: \(indexPath.row)")
            self?.reloadData()
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension PlanRouteRouteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            print("[PlanRoute] Start new segment tapped")
        } else if !points.isEmpty {
            print("[PlanRoute] Selected point at index: \(indexPath.row)")
        }
    }
}

final class PlanRoutePointCell: UITableViewCell {
    static let cellReuseId = "PlanRoutePointCell"

    private static let circleSize: CGFloat = 28
    private static let deleteSize: CGFloat = 24

    var onDelete: (() -> Void)?

    private let deleteButton = UIButton(type: .system)
    private let numberLabel = UILabel()
    private let numberContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dragHandleView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with point: PlanRoutePoint) {
        numberLabel.text = "\(point.index + 1)"
        titleLabel.text = point.name
        subtitleLabel.text = subtitle(for: point)
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.addTarget(self, action: #selector(onDeleteTapped), for: .touchUpInside)

        numberContainer.layer.cornerRadius = Self.circleSize / 2
        numberContainer.layer.borderWidth = 2
        numberContainer.layer.borderColor = UIColor.iconColorActive.cgColor
        numberLabel.font = .scaledSystemFont(ofSize: 13, weight: .semibold)
        numberLabel.textColor = .iconColorActive
        numberLabel.textAlignment = .center
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        numberContainer.addSubview(numberLabel)

        titleLabel.font = .scaledSystemFont(ofSize: 17)
        titleLabel.textColor = .textColorPrimary
        subtitleLabel.font = .scaledSystemFont(ofSize: 13)
        subtitleLabel.textColor = .textColorSecondary

        let textStack = UIStackView(arrangedSubviews: [subtitleLabel, titleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        dragHandleView.image = UIImage(systemName: "line.3.horizontal")
        dragHandleView.tintColor = .iconColorTertiary
        dragHandleView.contentMode = .scaleAspectFit

        [deleteButton, numberContainer, textStack, dragHandleView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: Self.deleteSize),
            deleteButton.heightAnchor.constraint(equalToConstant: Self.deleteSize),

            numberContainer.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 12),
            numberContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberContainer.widthAnchor.constraint(equalToConstant: Self.circleSize),
            numberContainer.heightAnchor.constraint(equalToConstant: Self.circleSize),
            numberLabel.centerXAnchor.constraint(equalTo: numberContainer.centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: numberContainer.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: numberContainer.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),

            dragHandleView.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 12),
            dragHandleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dragHandleView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            dragHandleView.widthAnchor.constraint(equalToConstant: 24),
            dragHandleView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    private func subtitle(for point: PlanRoutePoint) -> String {
        if point.isStart {
            return localizedString("starting_point")
        }
        let distance = OAOsmAndFormatter.getFormattedDistance(Float(point.distanceFromPrevious))
        if point.isDestination {
            return "\(distance) • \(localizedString("route_descr_destination"))"
        }
        return "\(distance) • \(Int(point.bearing))°"
    }

    @objc private func onDeleteTapped() {
        onDelete?()
    }
}

final class PlanRouteEmptyCell: UITableViewCell {
    static let cellReuseId = "PlanRouteEmptyCell"

    private static let iconSize: CGFloat = 30

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .groupBg
        selectionStyle = .none

        titleLabel.text = localizedString("plan_route_no_points_title")
        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0

        descriptionLabel.text = localizedString("plan_route_no_points_descr")
        descriptionLabel.font = .scaledSystemFont(ofSize: 15)
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.numberOfLines = 0

        iconView.image = .templateImageNamed("ic_custom_plan_route")
        iconView.tintColor = .iconColorActive
        iconView.contentMode = .scaleAspectFit

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        [textStack, iconView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            iconView.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 12),
            iconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize)
        ])
    }
}
