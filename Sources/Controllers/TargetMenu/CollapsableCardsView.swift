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
    weak var delegate: CollapsableCardViewDelegate?
    
    var title: String = ""
    
    var contentType: CollapsableCardsType = .onlinePhoto {
        didSet {
            cardsViewController.contentType = contentType
        }
    }
    
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
    
    private var cardsViewController: CardsViewController!
    private var сardsFilter: CardsFilter!
    private var bottomButton: UIButton?
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Init
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

        cardsViewController.didChangeHeightAction = { [weak self, weak cardsViewController] section, height in
            guard let self, let cardsViewController else { return }
            var newHeiht = height
            switch section {
            case .bigPhoto, .smallPhoto, .mapillaryBanner:
                switch contentType {
                case .onlinePhoto where сardsFilter.hasOnlyOnlinePhotosContent:
                    newHeiht += bottomContentHeight
                case .mapilary where сardsFilter.hasOnlyMapillaryPhotosContent:
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
    
    override func adjustHeight(forWidth width: CGFloat) {
        updateLayout(width: width)
    }
    
    func setCards(_ cards: [AbstractCard]) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            сardsFilter = CardsFilter(cards: cards)
            cardsViewController.сardsFilter = сardsFilter
            configureBottomButton()
        }
    }
    
    private func updateSpinner() {
        cardsViewController.showSpinner(show: isLoading)
    }
    
    private func configureBottomButton() {
        guard !сardsFilter.cardsIsEmpty else { return }
        
        switch contentType {
        case .onlinePhoto where сardsFilter.hasOnlyOnlinePhotosContent:
            setupButtomButton(title: localizedString("shared_string_view_all")) { [weak self, weak сardsFilter] _ in
                guard let self,
                      let сardsFilter,
                      let navigationController = OARootViewController.instance()?.navigationController else { return }
                
                let controller = GalleryGridViewController()
                controller.cards = сardsFilter.onlinePhotosSection
                controller.titleString = title
                navigationController.pushViewController(controller, animated: true)
            }
        case .mapilary where сardsFilter.hasOnlyMapillaryPhotosContent:
            setupButtomButton(title: localizedString("shared_string_explore")) { _ in
                OAMapillaryPlugin.installOrOpenMapillary()
            }
        default: break
        }
    }
    
    private func setupButtomButton(title: String, action: @escaping (UIAction) -> Void) {
        bottomButton = UIButton(type: .system, primaryAction: UIAction(title: title, handler: action))
        if let button = bottomButton {
            addButtonIfNeeded(button: button)
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
