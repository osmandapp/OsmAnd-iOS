//
//  SkyObjectInfoBottomSheet.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class SkyObjectInfoFragment: UIViewController {
    private let object: SkyObject
    var onClose: (() -> Void)?

    init(object: SkyObject) {
        self.object = object
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

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.numberOfLines = 0
        label.text = "\(object.niceName())\n\(object.type.localizedName)\nRA \(object.ra), Dec \(object.dec)"
        view.addSubview(closeButton)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        ])
    }
}
