//
//  StarCompassButton.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarCompassButton: StarMapButton {
    var onSingleTap: (() -> Void)?
    private let arrowView = UIImageView(image: AstroIcon.original("ic_custom_direction_compass"))
    private var currentRotation: CGFloat = 0
    private var arDirectionEnabled = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func update(mapRotation: CGFloat, animated: Bool = false) {
        currentRotation = mapRotation
        let transform = CGAffineTransform(rotationAngle: mapRotation * .pi / 180.0)
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.arrowView.transform = transform
            }
        } else {
            arrowView.transform = transform
        }
    }
    
    func setArDirectionEnabled(_ enabled: Bool) {
        guard enabled != arDirectionEnabled else { return }
        arDirectionEnabled = enabled
        updateArrowIcon()
    }

    override func updateTheme() {
        super.updateTheme()
        setImage(nil, for: .normal)
        updateArrowIcon()
        arrowView.transform = CGAffineTransform(rotationAngle: currentRotation * .pi / 180.0)
    }
    
    private func updateArrowIcon() {
        if arDirectionEnabled {
            let icon: UIImage? = .icCustomDirectionCompass.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: nightMode ? .dark : .light))
            arrowView.image = icon?.withRenderingMode(.alwaysOriginal)
        } else {
            let icon: UIImage? = .icCustomDirectionManual.imageAsset?.image(with: UITraitCollection(userInterfaceStyle: nightMode ? .dark : .light))
            arrowView.image = icon?.withRenderingMode(.alwaysOriginal)
        }
    }

    private func commonInit() {
        setImage(nil, for: .normal)
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        arrowView.contentMode = .center
        arrowView.isUserInteractionEnabled = false
        addSubview(arrowView)
        NSLayoutConstraint.activate([
            arrowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            arrowView.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 28),
            arrowView.heightAnchor.constraint(equalToConstant: 28)
        ])
        addAction(UIAction { [weak self] _ in
            self?.onSingleTap?()
        }, for: .touchUpInside)
        updateTheme()
    }
}
