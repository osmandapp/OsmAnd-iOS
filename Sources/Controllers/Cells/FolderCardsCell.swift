//
//  FolderCardsCell.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 09.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc(OAFolderCardsAddButtonPosition)
enum FolderCardsAddButtonPosition: Int {
    case end = 0
    case beginning = 1
}

@objc(OAFolderCardsConfig)
enum FolderCardsConfig: Int {
    case defaultConfig = 0
    case importTracks = 1
}

@objc(OAFolderCardsCellDelegate)
protocol FolderCardsCellDelegate: AnyObject {
    func onItemSelected(_ index: Int)
    func onAddFolderButtonPressed()
}

@objc(OAFolderCardsCell)
final class FolderCardsCell: UITableViewCell {

    private enum Layout {
        static let margin: CGFloat = 16
        static let cellWidth: CGFloat = 120
        static let cellHeight: CGFloat = 69
        static let rowHeight: CGFloat = 85
    }

    private struct Item {
        enum Kind { case folder, add }
        let title: String
        let size: String
        let color: UIColor
        let imageName: String
        let hidden: Bool
        let kind: Kind
    }

    @objc weak var delegate: FolderCardsCellDelegate?
    @objc weak var state: OACollectionViewCellState?
    @objc var cellIndex = IndexPath(row: 0, section: 0)

    var addButtonPosition: FolderCardsAddButtonPosition = .end
    var iconDefaultColor: UIColor = .iconColorActive
    var folderTitleDefaultColor: UIColor = .textColorActive
    var folderTitleSelectedDefaultColor: UIColor = .textColorActive

    @objc let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = Layout.margin
        layout.sectionInset = UIEdgeInsets(top: 0, left: Layout.margin, bottom: Layout.margin, right: Layout.margin)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .groupBg
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    private var items: [Item] = []
    private var selectedFolderIndex = 0
    private var originalGroupFont: UIFont?
    private var italicGroupFont: UIFont?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateContentOffset()
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .groupBg
        contentView.backgroundColor = .groupBg

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FolderCardCollectionViewCell.self, forCellWithReuseIdentifier: FolderCardCollectionViewCell.reuseIdentifier)

        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentView.heightAnchor.constraint(equalToConstant: Layout.rowHeight)
        ])
    }
    
    // MARK: - Config
    
    func configureCell(_ config: FolderCardsConfig) {
        switch config {
        case .defaultConfig: break
        case .importTracks:
            addButtonPosition = .beginning
            iconDefaultColor = .iconColorSelected
            folderTitleSelectedDefaultColor = .textColorPrimary
        }
    }

    // MARK: - ObjC API

    @objc(setValues:sizes:colors:hidden:addButtonTitle:withSelectedIndex:)
    func setValues(_ values: [String],
                   sizes: [NSNumber]?,
                   colors: [UIColor]?,
                   hidden: [NSNumber]?,
                   addButtonTitle: String,
                   withSelectedIndex index: Int32) {
        setValues(values,
                  sizes: sizes,
                  colors: colors,
                  hidden: hidden,
                  addButtonTitle: addButtonTitle,
                  withSelectedIndex: index,
                  addButtonPosition: addButtonPosition)
    }
    
    @objc(setValues:sizes:colors:hidden:addButtonTitle:withSelectedIndex:addButtonPosition:)
    func setValues(_ values: [String],
                   sizes: [NSNumber]?,
                   colors: [UIColor]?,
                   hidden: [NSNumber]?,
                   addButtonTitle: String,
                   withSelectedIndex index: Int32,
                   addButtonPosition position: FolderCardsAddButtonPosition) {
        self.addButtonPosition = position
        selectedFolderIndex = Int(index)
        
        let folderItems: [Item] = values.enumerated().map { i, title in
            let sizeNumber = sizes?[safe: i]
            let sizeString = sizeNumber.map { "\($0.intValue)" } ?? ""
            
            var color = colors?[safe: i] ?? iconDefaultColor
            
            let isHidden = hidden?[safe: i]?.boolValue ?? false
            let visible = !isHidden
            let imageName = visible ? "ic_custom_folder" : "ic_custom_folder_hidden_outlined"
            if !visible {
                color = .iconColorSecondary
            }
            
            return Item(title: title,
                        size: sizeString,
                        color: color,
                        imageName: imageName,
                        hidden: !visible,
                        kind: .folder)
        }
        
        let addItem = Item(title: addButtonTitle,
                           size: "",
                           color: .iconColorActive,
                           imageName: "ic_custom_add",
                           hidden: false,
                           kind: .add)

        switch position {
        case .end:
            items = folderItems + [addItem]
        case .beginning:
            items = [addItem] + folderItems
        }

        collectionView.reloadData()
    }

    @objc func setSelectedIndex(_ selectedIndex: Int) {
        let previous = selectedFolderIndex
        selectedFolderIndex = selectedIndex
        collectionView.reloadItems(at: [
            IndexPath(row: collectionIndex(forFolderIndex: previous), section: 0),
            IndexPath(row: collectionIndex(forFolderIndex: selectedFolderIndex), section: 0)
        ])
    }

    @objc func updateContentOffset() {
        guard let state else { return }

        if !state.containsValue(forIndex: cellIndex) {
            let initialOffset = calculateOffset(forFolderIndex: selectedFolderIndex)
            state.setOffset(initialOffset, forIndex: cellIndex)
            collectionView.contentOffset = initialOffset
        } else {
            var loadedOffset = state.getOffsetForIndex(cellIndex)
            if OAUtilities.getLeftMargin() > 0 {
                loadedOffset.x -= OAUtilities.getLeftMargin() - Layout.margin
            }
            collectionView.contentOffset = loadedOffset
        }
    }
    
    @objc func scrollToFolder(at folderIndex: Int, animated: Bool) {
        let indexPath = IndexPath(row: collectionIndex(forFolderIndex: folderIndex), section: 0)
        guard indexPath.row < collectionView.numberOfItems(inSection: 0),
              !collectionView.indexPathsForVisibleItems.contains(indexPath) else { return }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    }

    // MARK: - Mapping folder index <-> collection index

    private func collectionIndex(forFolderIndex folderIndex: Int) -> Int {
        switch addButtonPosition {
        case .end:
            return folderIndex
        case .beginning:
            return folderIndex + 1
        }
    }

    private func folderIndex(fromCollectionIndex collectionIndex: Int) -> Int {
        switch addButtonPosition {
        case .end:
            return collectionIndex
        case .beginning:
            return collectionIndex - 1
        }
    }

    private func isAddButton(at collectionIndex: Int) -> Bool {
        guard let item = items[safe: collectionIndex] else { return false }
        return item.kind == .add
    }

    // MARK: - Scroll offset

    private func saveOffset() {
        guard let state else { return }
        var offset = collectionView.contentOffset
        if OAUtilities.getLeftMargin() > 0 {
            offset.x += OAUtilities.getLeftMargin() - Layout.margin
        }
        state.setOffset(offset, forIndex: cellIndex)
    }

    private func calculateOffset(forFolderIndex folderIndex: Int) -> CGPoint {
        let index: Int
        switch addButtonPosition {
        case .end:
            index = collectionIndex(forFolderIndex: folderIndex)
        case .beginning:
            index = folderIndex
        }
        var selectedOffset = CGFloat(index) * (Layout.cellWidth + Layout.margin)
        let fullLength = CGFloat(items.count) * (Layout.cellWidth + Layout.margin)
        let screenWidth = OAUtilities.calculateScreenWidth()
        var maxOffset = fullLength - screenWidth + Layout.margin * 3
        if maxOffset < 0 {
            maxOffset = 0
        }
        if selectedOffset > maxOffset {
            selectedOffset = maxOffset
        }
        return CGPoint(x: selectedOffset, y: 0)
    }

    private func configureCardCell(_ cell: FolderCardCollectionViewCell, item: Item, selected: Bool) {
        if originalGroupFont == nil {
            originalGroupFont = cell.titleLabel.font
            if let descriptor = cell.titleLabel.font.fontDescriptor.withSymbolicTraits(.traitItalic) {
                italicGroupFont = UIFont(descriptor: descriptor, size: 0)
            }
        }

        cell.layer.cornerRadius = 9
        cell.titleLabel.text = item.title
        cell.descLabel.text = item.size
        cell.imageView.tintColor = item.color
        cell.imageView.image = .templateImageNamed(item.imageName)
        cell.backgroundColor = .groupBg
        cell.titleLabel.textColor = item.hidden ? .textColorSecondary : (selected ? folderTitleSelectedDefaultColor : folderTitleDefaultColor)
        cell.titleLabel.font = item.hidden ? italicGroupFont : originalGroupFont

        if selected {
            cell.layer.borderWidth = 2
            cell.layer.borderColor = UIColor.iconColorActive.cgColor
        } else {
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.buttonBgColorSecondary.cgColor
        }
        
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        if item.kind == .add {
            cell.accessibilityLabel = item.title
        } else {
            cell.accessibilityLabel = item.title
            cell.accessibilityValue = selected ? localizedString("shared_string_selected") : item.size
            if selected {
                cell.accessibilityTraits.insert(.selected)
            }
        }
        cell.imageView.isAccessibilityElement = false
    }
}

// MARK: - UICollectionViewDataSource

extension FolderCardsCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FolderCardCollectionViewCell.reuseIdentifier, for: indexPath) as? FolderCardCollectionViewCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.row]
        let selected = !isAddButton(at: indexPath.row) && folderIndex(fromCollectionIndex: indexPath.row) == selectedFolderIndex

        configureCardCell(cell, item: item, selected: selected)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FolderCardsCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: Layout.cellWidth, height: Layout.cellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction) {
            cell.backgroundColor = .iconColorDisabled
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.2, delay: 0, options: .allowUserInteraction) {
            cell.backgroundColor = .groupBg
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isAddButton(at: indexPath.row) {
            delegate?.onAddFolderButtonPressed()
        } else {
            let folderIndex = folderIndex(fromCollectionIndex: indexPath.row)
            delegate?.onItemSelected(folderIndex)
            setSelectedIndex(folderIndex)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        saveOffset()
    }
}
