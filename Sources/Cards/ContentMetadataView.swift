//
//  ContentMetadataView.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 10.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class ContentMetadataView: UIView {
    
    private let metadataStackView: MetadataStackView = {
        let stackView = MetadataStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view === self {
            return nil
        }
        return view
    }
    
    private func setupView() {
        addSubview(logoImageView)
        addSubview(metadataStackView)
        
        NSLayoutConstraint.activate([
            logoImageView.widthAnchor.constraint(equalToConstant: 30),
            logoImageView.heightAnchor.constraint(equalToConstant: 30),
            logoImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
       
        NSLayoutConstraint.activate([
            metadataStackView.leadingAnchor.constraint(equalTo: logoImageView.trailingAnchor, constant: 16),
            metadataStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            metadataStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }
    
    func updateMetadata(with metadata: Metadata?, imageName: String?) {
        metadataStackView.updateMetadata(with: metadata)
        if let imageName, !imageName.isEmpty {
            logoImageView.image = UIImage(named: imageName)
        } else {
            logoImageView.image = nil
        }
    }
}

final class MetadataStackView: UIStackView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        alignment = .leading
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view === self {
            return nil
        }
        return view
    }
    
    func updateMetadata(with metadata: Metadata?) {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let description = metadata?.description, !description.isEmpty {
            addArrangedSubview(createLabel(with: description))
        }
        if let formattedDate = metadata?.formattedDate, !formattedDate.isEmpty {
            addArrangedSubview(createLabel(with: localizedString("shared_string_date") + ": " + formattedDate))
        }
        if let author = metadata?.author, !author.isEmpty {
            addArrangedSubview(createLabel(with: localizedString("shared_string_author") + ": " + author))
        }
        if let license = metadata?.license, !license.isEmpty {
            addArrangedSubview(createLabel(with: localizedString("shared_string_license") + ": " + license))
        }
    }
    
    private func createLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 1
        label.text = text
        return label
    }
}
