//
//  BackupBannerCollectionViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

protocol BackupBannerCollectionViewCellDelegate: AnyObject {
    func didClose()
    func didOpenOsmAndCloud()
    func backupBannerHeight(_ banner: FreeBackupBanner, fittingWidth: CGFloat) -> CGFloat
}

final class BackupBannerCollectionViewCell: UICollectionViewCell {
    weak var delegate: BackupBannerCollectionViewCellDelegate? {
        didSet {
            updateBannerLayout()
        }
    }
    
    private var heightConstraint: NSLayoutConstraint?
    
    private lazy var banner: FreeBackupBanner? = {
        guard let banner = Bundle.main.loadNibNamed(FreeBackupBanner.reuseIdentifier, owner: self)?.first as? FreeBackupBanner else { return nil }
        banner.configure(bannerType: .favorite)
        banner.translatesAutoresizingMaskIntoConstraints = false
        return banner
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBanner()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupBanner() {
        guard let banner else { return }
        contentView.addSubview(banner)
        
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: contentView.topAnchor),
            banner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            banner.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        heightConstraint = banner.heightAnchor.constraint(equalToConstant: banner.frame.height)
        heightConstraint?.isActive = true
    }
    
    private func updateBannerLayout() {
        guard let banner else { return }
        banner.didOsmAndCloudButtonAction = { [weak self] in
            self?.delegate?.didOpenOsmAndCloud()
        }
        banner.didCloseButtonAction = { [weak self] in
            self?.delegate?.didClose()
        }
        
        let fittingWidth = contentView.bounds.width > 0.0 ? contentView.bounds.width : bounds.width
        let bannerHeight = delegate?.backupBannerHeight(banner, fittingWidth: fittingWidth) ?? banner.frame.height
        heightConstraint?.constant = bannerHeight
    }
}
