//
//  CollapsableCardsView.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

@objc
protocol CollapsableCardViewDelegate: AnyObject {
    @objc func onViewExpanded()
}

@objcMembers
final class CollapsableCardsView: OACollapsableView {
    weak var delegate: CollapsableCardViewDelegate?
    
    private let kMapillaryViewHeight: CGFloat = 156
    
    private var cardCollection: UICollectionView!
    private var nibNames: [String]!
    private var cards: [AbstractCard] = []
    
    private var viewAllButton: UIButton?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        nibNames = [
            ImageCard.getCellNibId(),
            NoImagesCard.getCellNibId(),
            MapillaryContributeCard.getCellNibId()
        ]
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 270, height: 160)
        layout.minimumInteritemSpacing = 16.0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 46, bottom: 0, right: 46)
        
        cardCollection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cardCollection.dataSource = self
        cardCollection.delegate = self
        cardCollection.showsHorizontalScrollIndicator = false
        cardCollection.showsVerticalScrollIndicator = false
        
        cardCollection.translatesAutoresizingMaskIntoConstraints = false
        
        registerSupportedNibs()
        addSubview(cardCollection)
        
        NSLayoutConstraint.activate([
            cardCollection.topAnchor.constraint(equalTo: topAnchor),
            cardCollection.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardCollection.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardCollection.heightAnchor.constraint(equalToConstant: 156)
        ])
        addViewAllButtonIfNeeded()
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
        if !collapsed {
            buildViews()
            cardCollection.reloadData()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if !collapsed {
            buildViews()
            cardCollection.reloadData()
        }
    }
    
    func updateLayout(width: CGFloat) {
        frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: width, height: kMapillaryViewHeight)
        cardCollection.frame = CGRect(x: 0, y: 0, width: width, height: kMapillaryViewHeight)
    }
    
    func adjustHeightForWidth(width: CGFloat) {
        updateLayout(width: width)
    }
    
    func setCards(_ cards: [AbstractCard]) {
        DispatchQueue.main.async {
            self.cards = cards
            for card in cards {
                card.delegate = self
            }
            
            self.buildViews()
            self.cardCollection.reloadData()
        }
    }
    
    private func buildViews() {
        cardCollection.backgroundColor = .groupBg
    }
    
    private func registerSupportedNibs() {
        for name in nibNames {
            let nib = UINib(nibName: name, bundle: nil)
            cardCollection.register(nib, forCellWithReuseIdentifier: name)
        }
    }
    
    private func addViewAllButtonIfNeeded() {
        guard viewAllButton == nil else { return }
        viewAllButton = UIButton(type: .system, primaryAction: UIAction(title: localizedString("shared_string_view_all"), handler: { _ in
            print("Button tapped!")
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
extension CollapsableCardsView: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let card = cards[indexPath.row]
        let reuseIdentifier = type(of: card).getCellNibId()
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if !collapsed {
            card.build(in: cell)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        cards[indexPath.row].onCardPressed(OARootViewController.instance().mapPanel)
    }
}

// MARK: - AbstractCardDelegate
extension CollapsableCardsView: AbstractCardDelegate {
    func requestCardReload(_ card: AbstractCard) {
        card.update()
        if let row = cards.firstIndex(of: card) {
            let path = IndexPath(row: row, section: 0)
            cardCollection.reloadItems(at: [path])
        }
    }
}
