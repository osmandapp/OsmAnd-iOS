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

@objcMembers
final class CollapsableCardsView: OACollapsableView {
    weak var delegate: CollapsableCardViewDelegate?
    
    private var cardsViewController: CardsViewController!
    private var viewAllButton: UIButton?
    private var heightConstraint: NSLayoutConstraint?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        cardsViewController = CardsViewController(frame: .zero)
        cardsViewController.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cardsViewController)
        
        NSLayoutConstraint.activate([
            cardsViewController.topAnchor.constraint(equalTo: topAnchor),
            cardsViewController.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardsViewController.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        heightConstraint = cardsViewController.heightAnchor.constraint(equalToConstant: 170)
        heightConstraint?.isActive = true

        cardsViewController.didChanggeHeightAction = { [weak self] section, height in
            guard let self else { return }
            switch section {
            case .noInternet, .noPhotos:
                if heightConstraint?.constant != CGFloat(height) {
                    heightConstraint?.constant = CGFloat(height)
                    if let superview = cardsViewController.superview {
                       var frame = superview.frame
                        frame.size.height = CGFloat(height)
                        superview.frame = frame
                        delegate?.onRecalculateHeight()
    //                    superview.setNeedsLayout()
    //                    superview.layoutIfNeeded()
                    }
                }
            default:
                return
            }
        }
    }
    
    override var collapsed: Bool {
        didSet {
            OAAppSettings.sharedManager().onlinePhotosRowCollapsed.set(collapsed)
            
            if !collapsed, let delegate {
                delegate.onViewExpanded()
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        guard !collapsed else { return }
        
        cardsViewController.reloadData()
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard !collapsed else { return }
        
        cardsViewController.reloadData()
    }
    
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
            
            if cardsViewController.hasPhoto {
                // TODO: wiki || mapillary
                addViewAllButtonIfNeeded()
            }
           // cardsViewController.reloadData()
        }
    }
    
    private func updateLayout(width: CGFloat) {
        var rect = cardsViewController.frame
        rect.size.width = width
        cardsViewController.frame = rect
    }
    
    private func addViewAllButtonIfNeeded() {
        guard viewAllButton == nil else { return }
        viewAllButton = UIButton(type: .system, primaryAction: UIAction(title: localizedString("shared_string_view_all"), handler: { _ in
            print("Button tapped view all!")
        }))
        guard let viewAllButton else { return }
        
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .buttonBgColorTertiary
        config.baseForegroundColor = .buttonTextColorSecondary
        config.background.cornerRadius = 9
        config.cornerStyle = .fixed
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        viewAllButton.configuration = config
        
        viewAllButton.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(viewAllButton)
        
        NSLayoutConstraint.activate([
            viewAllButton.heightAnchor.constraint(equalToConstant: 44),
            viewAllButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            viewAllButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
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
