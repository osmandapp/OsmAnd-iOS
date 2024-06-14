//
//  DownloadingCellBaseHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 01/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc enum ItemStatusType: Int {
    case idle, started, inProgress, finished
}

@objc enum DownloadingCellRightIconType: Int {
    case hideIconAfterDownloading, showIconAlways, showShevronAlways, showIconAndShevronAlways, showShevronBeforeDownloading, showShevronAfterDownloading, showInfoAndShevronAfterDownloading
}

@objcMembers
class DownloadingCellBaseHelper: NSObject {
    
    var rightIconName: String?
    var rightIconColor: UIColor?
    var isBoldTitleStyle = false
    var isAlwaysClickable = false
    var isDownloadedRecolored = false
    var rightIconStyle: DownloadingCellRightIconType = .hideIconAfterDownloading
    
    private var cells = [String: DownloadingCell]()
    private var statuses = [String: ItemStatusType]()
    private var progresses = [String: Float]()
    private weak var hostTableView: UITableView?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func onApplicationWillEnterForeground() {
        hostTableView?.reloadData()
        refreshCellSpinners()
    }
    
    func getHostTableView() -> UITableView? {
        hostTableView
    }
    
    func setHostTableView(_ tableView: UITableView?) {
        hostTableView = tableView
    }
    
    // MARK: - Resource methods
    
    func helperHasItemFor(_ resourceId: String) -> Bool {
        statuses[resourceId] != nil
    }
    
    // Override in subclass
    func isInstalled(_ resourceId: String) -> Bool {
        if helperHasItemFor(resourceId) {
            if statuses[resourceId] == .finished {
                return true
            }
        }
        return false
    }
    
    // Override in subclass
    func isDownloading(_ resourceId: String) -> Bool {
        if helperHasItemFor(resourceId) {
            return statuses[resourceId] == .inProgress
        }
        return false
    }
    
    func startDownload(_ resourceId: String) {
        // Override in subclass
    }
    
    func stopDownload(_ resourceId: String) {
        // Override in subclass
    }
    
    // MARK: - Cell setup methods
    
    func getOrCreateCell(_ resourceId: String) -> DownloadingCell? {
        if statuses[resourceId] == nil {
            statuses[resourceId] = .idle
        }
        if progresses[resourceId] == nil {
            progresses[resourceId] = 0
        }
        var cell = cells[resourceId]
        if cell == nil {
            cell = setupCell(resourceId)
            cells[resourceId] = cell
        }
        return cell
    }
    
    // Override in subclass
    func setupCell(_ resourceId: String) -> DownloadingCell? {
        setupCell(resourceId: resourceId, title: "", isTitleBold: false, desc: nil, leftIconName: nil, rightIconName: nil, isDownloading: false)
    }
    
    // Override in subclass
    func setupCell(resourceId: String, title: String?, isTitleBold: Bool, desc: String?, leftIconName: String?, rightIconName: String?, isDownloading: Bool) -> DownloadingCell? {
        
        guard let hostTableView else { return nil }
        var cell = cells[resourceId]
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(DownloadingCell.reuseIdentifier, owner: self, options: nil)
            cell = nib?.first as? DownloadingCell
        }
        guard let cell else { return nil }
        
        cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        cell.leftIconView.tintColor = .iconColorDefault
        cell.rightIconView.tintColor = getRightIconColor()
        cell.rightIconView.image = UIImage.templateImageNamed(getRightIconName())
        
        if let leftIconName, !leftIconName.isEmpty {
            cell.leftIconVisibility(true)
            cell.leftIconView.image = UIImage.templateImageNamed(leftIconName)
            if isInstalled(resourceId) && isDownloadedRecolored {
                cell.leftIconView.tintColor = .iconColorActive
            } else {
                cell.leftIconView.tintColor = .iconColorDefault
            }
        } else {
            cell.leftIconVisibility(false)
        }
        
        cell.titleLabel.text = title != nil ? title : ""
        if isTitleBold || isBoldTitleStyle {
            cell.titleLabel.font = UIFont.scaledSystemFont(ofSize: 17, weight: .medium)
            cell.titleLabel.textColor = .textColorActive
        } else {
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
            cell.titleLabel.textColor = .textColorPrimary
        }
        
        if let desc, !desc.isEmpty {
            cell.descriptionVisibility(true)
            cell.descriptionLabel.text = desc
            cell.descriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            cell.descriptionLabel.textColor = .textColorSecondary
        } else {
            cell.descriptionVisibility(false)
        }
        
        if isDownloading {
            cell.rightIconVisibility(false)
            cells[resourceId] = cell
            refreshCellProgress(resourceId)
        } else {
            setupRightIconForIdleCell(cell: cell, rightIconName: rightIconName, resourceId: resourceId)
        }
        return cell
    }
    
    private func setupRightIconForIdleCell(cell: DownloadingCell, rightIconName: String?, resourceId: String) {
        
        var showIcon = false
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.rightIconVisibility(false)
        
        if rightIconStyle == .hideIconAfterDownloading {
            showIcon = !isInstalled(resourceId)
        } else if rightIconStyle == .showIconAlways {
            showIcon = true
        } else if rightIconStyle == .showShevronAlways {
            cell.accessoryType = .disclosureIndicator
        } else if rightIconStyle == .showIconAndShevronAlways {
            cell.accessoryType = .disclosureIndicator
            showIcon = true
        } else if rightIconStyle == .showShevronBeforeDownloading {
            if !isInstalled(resourceId) {
                cell.accessoryType = .disclosureIndicator
                showIcon = true
            }
        } else if rightIconStyle == .showShevronAfterDownloading {
            if isInstalled(resourceId) {
                cell.accessoryType = .disclosureIndicator
            } else {
                showIcon = true
            }
        } else if rightIconStyle == .showInfoAndShevronAfterDownloading {
            if isInstalled(resourceId) {
                cell.accessoryType = .detailDisclosureButton
            } else {
                showIcon = true
            }
        }
        
        if showIcon {
            cell.rightIconView.image = UIImage.templateImageNamed(getRightIconName())
            cell.rightIconView.tintColor = getRightIconColor()
            cell.rightIconVisibility(true)
        }
    }
    
    func getRightIconName() -> String {
        rightIconName ?? "ic_custom_download"
    }
    
    func getRightIconColor() -> UIColor {
        if let rightIconColor {
            return rightIconColor
        }
        return .iconColorActive
    }
    
    // Default on click behavior
    func onCellClicked(_ resourceId: String) {
        if !isInstalled(resourceId) || isAlwaysClickable {
            if isDownloading(resourceId) {
                stopDownload(resourceId)
            } else {
                startDownload(resourceId)
            }
        }
    }
    
    // MARK: - Cell progress update methods
    
    func refreshCellSpinners() {
        cells.values.forEach { cell in
            if let progressView = cell.accessoryView as? FFCircularProgressView, progressView.isSpinning {
                progressView.startSpinProgressBackgroundLayer()
            }
        }
    }
    
    func refreshCellProgress(_ resourceId: String) {
        var progress: Float = 0
        var status: ItemStatusType = .idle
        if let savedProgress = progresses[resourceId] {
            progress = savedProgress
        }
        if let savedStatus = statuses[resourceId] {
            status = savedStatus
        }
        setCellProgress(resourceId: resourceId, progress: progress, status: status)
    }
    
    func setCellProgress(resourceId: String, progress: Float, status: ItemStatusType) {
        
        guard helperHasItemFor(resourceId) else { return }
        
        saveStatus(resourceId: resourceId, status: status)
        saveProgress(resourceId: resourceId, progress: progress)
        var currentStatus = status
        
        guard let cell = cells[resourceId] else { return }
        var progressView = cell.accessoryView as? FFCircularProgressView
        
        if progressView == nil && status != .finished && status != .idle {
            progressView = FFCircularProgressView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
            progressView?.iconView = UIView()
            progressView?.tintColor = .iconColorActive
            cell.accessoryView = progressView
            cell.rightIconVisibility(false)
            currentStatus = .started
        }
        
        if currentStatus == .started {
            if let progressView {
                progressView.iconPath = UIBezierPath()
                progressView.progress = 0
                if !progressView.isSpinning {
                    progressView.startSpinProgressBackgroundLayer()
                }
            }
        } else if currentStatus == .inProgress {
            if let progressView {
                progressView.iconPath = nil
                if progressView.isSpinning {
                    progressView.stopSpinProgressBackgroundLayer()
                }
                var visualProgress = progress - 0.001
                if visualProgress < 0.001 {
                    visualProgress = 0.001
                }
                progressView.progress = CGFloat(visualProgress)
            }
        } else if currentStatus == .finished {
            if let progressView {
                progressView.iconPath = OAResourcesUISwiftHelper.tickPath(progressView)
                progressView.progress = 0
                if !progressView.isSpinning {
                    progressView.startSpinProgressBackgroundLayer()
                }
            }
            
            if progress < 1 {
                // Downloading interupted by user
                saveStatus(resourceId: resourceId, status: .idle)
            }
            setupRightIconForIdleCell(cell: cell, rightIconName: getRightIconName(), resourceId: resourceId)
        }
    }
    
    func saveStatus(resourceId: String, status: ItemStatusType) {
        statuses[resourceId] = status
    }
    
    func saveProgress(resourceId: String, progress: Float) {
        progresses[resourceId] = progress
    }
    
    func cleanCellCache() {
        cells.removeAll()
    }
}
