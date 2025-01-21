//
//  OACollapsableCardViewDelegate.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 20.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//


//import UIKit
//
//// Constants for card types
//let TYPE_MAPILLARY_PHOTO = "mapillary-photo"
//let TYPE_MAPILLARY_CONTRIBUTE = "mapillary-contribute"
//let TYPE_MAPILLARY_EMPTY = "mapillary-empty"
//let TYPE_URL_PHOTO = "url-photo"
//let TYPE_WIKIMEDIA_PHOTO = "wikimedia-photo"
//let TYPE_WIKIDATA_PHOTO = "wikidata-photo"
//
//// Protocol definition for the delegate
//protocol CollapsableCardViewDelegate: AnyObject {
//    func onViewExpanded()
//}
//
//// The OACollapsableCardsView class
//class CollapsableCardsView: OACollapsableView, UICollectionViewDataSource, UICollectionViewDelegate, OAAbstractCardDelegate {
//    
//    private var _cardCollection: UICollectionView!
//    private var nibNames: [String]!
//    private var cards: [OAAbstractCard] = []
//    
//    weak var delegate: CollapsableCardViewDelegate?
//    
//    private static let kMapillaryViewHeight: CGFloat = 170
//
//    // Initializer
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        nibNames = [
//            OAImageCard.getCellNibId(),
//            OANoImagesCard.getCellNibId(),
//            OAMapillaryContributeCard.getCellNibId()
//        ]
//        
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        layout.itemSize = CGSize(width: 270, height: 160)
//        layout.minimumInteritemSpacing = 16.0
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 46, bottom: 0, right: 46)
//        
//        _cardCollection = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), collectionViewLayout: layout)
//        _cardCollection.dataSource = self
//        _cardCollection.delegate = self
//        _cardCollection.showsHorizontalScrollIndicator = false
//        _cardCollection.showsVerticalScrollIndicator = false
//        
//        registerSupportedNibs()
//        
//        self.addSubview(_cardCollection)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // Register the nibs for the cards
//    private func registerSupportedNibs() {
//        for name in nibNames {
//            _cardCollection.register(UINib(nibName: name, bundle: nil), forCellWithReuseIdentifier: name)
//        }
//    }
//    
//    // Handle the collapse/expand state
//    override func setCollapsed(_ collapsed: Bool) {
//        super.setCollapsed(collapsed)
//        OAAppSettings.sharedManager.onlinePhotosRowCollapsed.set(collapsed)
//        
//        if !collapsed, let delegate = delegate {
//            delegate.onViewExpanded()
//        }
//    }
//
//    // Build the views for the collection
//    private func buildViews() {
//        _cardCollection.backgroundColor = UIColor(named: ACColorNameGroupBg)
//    }
//    
//    // Handle selection/highlighting of cards
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        if !self.collapsed {
//            buildViews()
//            _cardCollection.reloadData()
//        }
//    }
//    
//    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
//        if !self.collapsed {
//            buildViews()
//            _cardCollection.reloadData()
//        }
//    }
//
//    // Adjust the height of the view based on the width
//    func updateLayout(width: CGFloat) {
//        self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: width, height: OACollapsableCardsView.kMapillaryViewHeight)
//        _cardCollection.frame = CGRect(x: 0, y: 0, width: width, height: OACollapsableCardsView.kMapillaryViewHeight)
//    }
//    
//    // Adjust height for a given width
//    func adjustHeightForWidth(width: CGFloat) {
//        updateLayout(width: width)
//    }
//    
//    // Set the cards and reload the collection view
//    func setCards(cards: [OAAbstractCard]) {
//        DispatchQueue.main.async {
//            self.cards = cards
//            for card in cards {
//                card.delegate = self
//            }
//            
//            self.buildViews()
//            self._cardCollection.reloadData()
//        }
//    }
//    
//    // MARK: - UICollectionViewDataSource
//    
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return cards.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let card = cards[indexPath.row]
//        let reuseIdentifier = card.className.getCellNibId()
//        
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
//        if let cell = cell as? OAAbstractCardCell {
//            if !self.collapsed {
//                card.build(cell)
//            }
//        }
//        
//        return cell
//    }
//    
//    // MARK: - UICollectionViewDelegate
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
//        cards[indexPath.row].onCardPressed(OARootViewController.instance().mapPanel)
//    }
//    
//    // MARK: - AbstractCardDelegate
//    
//    func requestCardReload(card: OAAbstractCard) {
//        card.update()
//        if let row = cards.firstIndex(of: card) {
//            let path = IndexPath(row: row, section: 0)
//            _cardCollection.reloadItems(at: [path])
//        }
//    }
//}
