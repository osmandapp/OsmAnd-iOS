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
    case hideIconAfterDownloading,
         showIconAlways,
         showShevronAlways,
         showIconAndShevronAlways,
         showIconAndShevronBeforeDownloading,
         showShevronBeforeDownloading,
         showShevronAfterDownloading,
         showInfoAndShevronAfterDownloading,
         showDoneIconAfterDownloading
}

@objcMembers
class DownloadingCellBaseHelper: NSObject {
    
    var leftIconColor: UIColor?
    var rightIconName: String?
    var rightIconColor: UIColor?
    var isBoldTitleStyle = false
    var isAlwaysClickable = false
    var isDownloadedLeftIconRecolored = false
    var rightIconStyle: DownloadingCellRightIconType = .hideIconAfterDownloading
    
    private var cells = [String: DownloadingCell]()
    private var statuses = [String: ItemStatusType]()
    private var progresses = [String: Float]()
    private weak var hostTableView: UITableView?
    
    private var backgroundStateObserver: OAAutoObserverProxy?
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        backgroundStateObserver = OAAutoObserverProxy(self, withHandler: #selector(refreshDownloadingContent), andObserve: OsmAndApp.swiftInstance().backgroundStateObservable)
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
    
    // Override in subclass
    func isFinished(_ resourceId: String) -> Bool {
        isInstalled(resourceId)
    }
    
    func startDownload(_ resourceId: String) {
        // Override in subclass
    }
    
    func stopDownload(_ resourceId: String) {
        // Override in subclass
    }
    
    func helperHasItemFor(_ resourceId: String) -> Bool {
        statuses[resourceId] != nil
    }
    
    func allResourceIds() -> [String] {
        Array(statuses.keys)
    }

    // MARK: - Cell setup methods
    
    func getOrCreateCell(_ resourceId: String) -> DownloadingCell? {
        getOrCreateCell(resourceId,
                        title: "",
                        desc: nil,
                        leftIcon: nil,
                        isDownloading: false)
    }

    func getOrCreateCell(_ resourceId: String,
                         title: String?,
                         desc: Any?,
                         leftIcon: Any?,
                         isDownloading: Bool) -> DownloadingCell? {
        if statuses[resourceId] == nil {
            statuses[resourceId] = .idle
        }
        if progresses[resourceId] == nil {
            progresses[resourceId] = 0
        }
        guard let cell = cells[resourceId] else {
            let newCell = setupCell(resourceId,
                                    title: title,
                                    isTitleBold: false,
                                    desc: desc,
                                    leftIcon: leftIcon,
                                    isDownloading: isDownloading)
            cells[resourceId] = newCell
            return newCell
        }
        let status = getStatus(resourceId: resourceId)
        if status != .idle {
            updateDesc(resourceId, cell: cell, desc: desc)
            updateLeftIcon(resourceId, cell: cell, leftIcon: leftIcon)
            updateRightIcon(resourceId, cell: cell, isDownloading: isDownloading)
        }
        return cell
    }

    func updateLeftIcon(_ resourceId: String,
                        cell: DownloadingCell,
                        leftIcon: Any?) {
        if let leftIcon {
            cell.leftIconVisibility(true)
            if let leftIconName = leftIcon as? String {
                cell.leftIconView.image = UIImage.templateImageNamed(leftIconName)
            } else if let leftIconImage = leftIcon as? UIImage {
                cell.leftIconView.image = leftIconImage
            }
            updateLeftIconColor(resourceId, cell: cell, color: nil)
        } else {
            cell.leftIconVisibility(false)
        }
    }

    func updateLeftIconColor(_ resourceId: String,
                             cell: DownloadingCell?,
                             color: UIColor?) {
        var downloadingCell = cell
        if downloadingCell == nil {
            downloadingCell = cells[resourceId]
        }
        guard let downloadingCell else { return }
        if let color {
            downloadingCell.leftIconView.tintColor = color
        } else if isInstalled(resourceId) && isDownloadedLeftIconRecolored {
            downloadingCell.leftIconView.tintColor = leftIconColor != nil ? leftIconColor : .iconColorActive
        } else {
            downloadingCell.leftIconView.tintColor = .iconColorDefault
        }
    }

    func updateRightIcon(_ resourceId: String,
                         cell: DownloadingCell,
                         isDownloading: Bool) {
        if isDownloading {
            cell.rightIconVisibility(false)
            cells[resourceId] = cell
            refreshCellProgress(resourceId)
        } else {
            setupRightIconForIdleCell(cell: cell, resourceId: resourceId)
        }
    }

    func updateDesc(_ resourceId: String,
                    cell: DownloadingCell?,
                    desc: Any?) {
        var downloadingCell = cell
        if downloadingCell == nil {
            downloadingCell = cells[resourceId]
        }
        guard let downloadingCell else { return }
        if let desc {
            downloadingCell.descriptionVisibility(true)
            if let descStr = desc as? String, !descStr.isEmpty {
                downloadingCell.descriptionLabel.attributedText = nil
                downloadingCell.descriptionLabel.text = descStr
                downloadingCell.descriptionLabel.font = UIFont.monospacedFont(at: 12, withTextStyle: .body)
                downloadingCell.descriptionLabel.textColor = .textColorSecondary
            } else if let descAttr = desc as? NSAttributedString, descAttr.length > 0 {
                downloadingCell.descriptionLabel.text = nil
                downloadingCell.descriptionLabel.attributedText = descAttr
            }
        } else {
            downloadingCell.descriptionVisibility(false)
        }
    }

    // Override in subclass
    func setupCell(_ resourceId: String,
                   title: String?,
                   isTitleBold: Bool,
                   desc: Any?,
                   leftIcon: Any?,
                   isDownloading: Bool) -> DownloadingCell? {
        var cell = cells[resourceId]
        if cell == nil {
            let nib = Bundle.main.loadNibNamed(DownloadingCell.reuseIdentifier, owner: self, options: nil)
            cell = nib?.first as? DownloadingCell
        }
        guard let cell else { return nil }

        cell.titleLabel.text = title
        cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        if isTitleBold || isBoldTitleStyle {
            cell.titleLabel.font = UIFont.scaledSystemFont(ofSize: 17, weight: .medium)
            cell.titleLabel.textColor = .textColorActive
        } else {
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
            cell.titleLabel.textColor = .textColorPrimary
        }

        updateDesc(resourceId, cell: cell, desc: desc)
        updateLeftIcon(resourceId, cell: cell, leftIcon: leftIcon)
        updateRightIcon(resourceId, cell: cell, isDownloading: isDownloading)

        return cell
    }
    
    private func setupRightIconForIdleCell(cell: DownloadingCell, resourceId: String) {
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
        } else if rightIconStyle == .showIconAndShevronBeforeDownloading {
            if !isInstalled(resourceId) {
                cell.accessoryType = .disclosureIndicator
                showIcon = true
            }
        } else if rightIconStyle == .showShevronBeforeDownloading {
            if !isInstalled(resourceId) {
                cell.accessoryType = .disclosureIndicator
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
        } else if rightIconStyle == .showDoneIconAfterDownloading {
            showIcon = true
        }
        
        if showIcon {
            cell.rightIconView.image = UIImage.templateImageNamed(getRightIconName(resourceId))
            cell.rightIconView.tintColor = getRightIconColor()
            cell.rightIconVisibility(true)
        }
    }
    
    func getRightIconName(_ resourceId: String) -> String {
        if let rightIconName {
            return rightIconName
        } else if rightIconStyle == .showDoneIconAfterDownloading && isFinished(resourceId) {
            return "ic_custom_done"
        }
        return "ic_custom_download"
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
        
        if currentStatus == .started || currentStatus == .inProgress {
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
            setupRightIconForIdleCell(cell: cell, resourceId: resourceId)
        }
    }
    
    func getStatus(resourceId: String) -> ItemStatusType? {
        statuses[resourceId]
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
    
    @objc func refreshDownloadingContent() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshCellSpinners()
        }
    }
}
