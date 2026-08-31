//
//  DescriptionDeviceCell.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 31.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class DescriptionDeviceCell: UITableViewCell {
    private(set) var deviceHeader: DescriptionDeviceHeader?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupView(_ header: DescriptionDeviceHeader) {
        selectionStyle = .none

        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = .clear
        header.hideBottomDivider()
        contentView.addSubview(header)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: contentView.topAnchor),
            header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            header.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            header.heightAnchor.constraint(equalToConstant: 156)
        ])

        deviceHeader = header
    }

    func configure(header: DescriptionDeviceHeader) {
        guard deviceHeader !== header else { return }
        deviceHeader?.removeFromSuperview()
        setupView(header)
    }
}
