//
//  CollapsableCardsView.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
protocol CollapsableCardViewDelegate: AnyObject {
    @objc func onViewExpanded()
    @objc func onRecalculateHeight()
}

@objc enum CollapsableCardsType: Int {
     case onlinePhoto, mapilary
 }

@objcMembers
final class CollapsableCardsView: OACollapsableView {
    var contentType: CollapsableCardsType = .onlinePhoto
    
    weak var delegate: CollapsableCardViewDelegate?
    
    var isLoading = false {
        didSet {
            updateSpinner()
        }
    }
    
    override var collapsed: Bool {
        didSet {
            switch contentType {
            case .onlinePhoto:
                OAAppSettings.sharedManager().onlinePhotosRowCollapsed.set(collapsed)
            case .mapilary:
                OAAppSettings.sharedManager().mapillaryPhotosRowCollapsed.set(collapsed)
            }
            if !collapsed, let delegate {
                delegate.onViewExpanded()
            }
        }
    }
    
    private let bottomContentHeight: Float = 68.0
    
    // swiftlint:disable force_unwrapping
    private var cardsViewController: CardsViewController!
    // swiftlint:enable force_unwrapping
    private var viewAllButton: UIButton?
    private var exploreButton: UIButton?
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        cardsViewController = CardsViewController(frame: .zero)
        cardsViewController.contentType = contentType
        cardsViewController.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardsViewController)
        
        NSLayoutConstraint.activate([
            cardsViewController.topAnchor.constraint(equalTo: topAnchor),
            cardsViewController.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardsViewController.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        heightConstraint = cardsViewController.heightAnchor.constraint(equalToConstant: 170)
        heightConstraint?.isActive = true

        cardsViewController.didChangeHeightAction = { [weak self, weak cardsViewController] section, height in
            guard let self, let cardsViewController else { return }
            var newHeiht = height
            switch section {
            case .bigPhoto, .smallPhoto, .mapillaryBanner:
                switch contentType {
                case .onlinePhoto where cardsViewController.cards.hasOnlyOnlinePhotosContent:
                    newHeiht += bottomContentHeight
                case .mapilary where cardsViewController.cards.hasOnlyMapillaryPhotosContent:
                    newHeiht += bottomContentHeight
                default: break
                }
            default: break
            }
            
            if heightConstraint?.constant != CGFloat(newHeiht) {
                heightConstraint?.constant = CGFloat(newHeiht)
                if let superview = cardsViewController.superview {
                   var frame = superview.frame
                    frame.size.height = CGFloat(newHeiht)
                    superview.frame = frame
                    delegate?.onRecalculateHeight()
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        guard !collapsed else { return }
        
        cardsViewController.reloadData()
    }
    
//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//      //  guard !collapsed else { return }
//        
//        //cardsViewController.reloadData()
//    }
    
    override func adjustHeight(forWidth width: CGFloat) {
        updateLayout(width: width)
    }
    
    func setCards(_ cards: [AbstractCard]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            cardsViewController.cards = cards
            for card in cards {
                card.delegate = self
            }
            configereBottomButton(with: cards)
        }
    }
    
    private func updateSpinner() {
        cardsViewController.showSpinner(show: isLoading)
    }
    
    private func configereBottomButton(with cards: [AbstractCard]) {
        guard !cards.isEmpty else { return }
        
        switch contentType {
        case .onlinePhoto:
            if cards.hasOnlyOnlinePhotosContent {
                viewAllButton = UIButton(type: .system, primaryAction: UIAction(title: localizedString("shared_string_view_all"), handler: { _ in
                    // TODO:
                    print("viewAllButton tapped view all!")
                }))
                addButtonIfNeeded(button: viewAllButton!)
            }
        case .mapilary:
            if cards.hasOnlyMapillaryPhotosContent {
                exploreButton = UIButton(type: .system, primaryAction: UIAction(title: localizedString("shared_string_explore"), handler: { _ in
                    OAMapillaryPlugin.installOrOpenMapillary()
                }))
                addButtonIfNeeded(button: exploreButton!)
            }
        }
    }
    
    private func updateLayout(width: CGFloat) {
        var rect = cardsViewController.frame
        rect.size.width = width
        cardsViewController.frame = rect
        
        if let superview = cardsViewController.superview {
           var frame = superview.frame
            frame.size.width = CGFloat(width)
            superview.frame = frame
        }
    }
    
    private func addButtonIfNeeded(button: UIButton) {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .buttonBgColorTertiary
        config.baseForegroundColor = .buttonTextColorSecondary
        config.background.cornerRadius = 9
        config.cornerStyle = .fixed
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        button.configuration = config
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(button)
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44),
            button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
}

// MARK: - UICollectionViewDelegate | UICollectionViewDataSource
//extension CollapsableCardsView: UICollectionViewDelegate, UICollectionViewDataSource {
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        1
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        cards.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let card = cards[indexPath.row]
//        let reuseIdentifier = type(of: card).getCellNibId()
//        
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
//        if !collapsed {
//            card.build(in: cell)
//        }
//        
//        return cell
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
//        cards[indexPath.row].onCardPressed(OARootViewController.instance().mapPanel)
//    }
//}

// MARK: - AbstractCardDelegate
extension CollapsableCardsView: AbstractCardDelegate {
    func requestCardReload(_ card: AbstractCard) {
        print("")
//        card.update()
//        if let row = cards.firstIndex(of: card) {
//            let path = IndexPath(row: row, section: 0)
//           // cardCollection.reloadItems(at: [path])
//        }
    }
}
