//
//  DownloadMapProgressViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 19.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

private enum RowKey: String {
    case numberOfTiles
    case downloadSize
    case failedTiles
    case retry
}

@objcMembers
final class DownloadMapProgressViewController: OABaseButtonsViewController, OATileDownloadDelegate {
    private let numberOfTiles: Int
    private let estimatedTileSize: Int64 = 12000
    private let progressLock = NSLock()
    private var tileDownloader: OAMapTileDownloader
    private var downloadedNumberOfTiles = 0
    private var failedNumberOfTiles = 0
    private var isFinished = false
    private var isCancelled = false
    
    init(downloader: OAMapTileDownloader, numberOfTiles: Int) {
        self.tileDownloader = downloader
        self.numberOfTiles = numberOfTiles
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tileDownloader.delegate = self
        if numberOfTiles > 0 {
            tileDownloader.startDownload()
        } else {
            onDownloadFinished()
        }
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            cancelDownload()
        }
    }
    
    override func registerCells() {
        addCell(OADownloadProgressBarCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String {
        localizedString("shared_string_download_map")
    }
    
    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        .orange
    }
    
    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onLeftNavbarButtonPressed))
    }
    
    override func getBottomButtonTitle() -> String {
        localizedString(isFinished ? "shared_string_close" : "shared_string_cancel")
    }
    
    override func getBottomColorScheme() -> EOABaseBottomColorScheme {
        .white
    }
    
    override func tableStyle() -> UITableView.Style {
        .grouped
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func generateData() {
        progressLock.lock()
        let failedTiles = failedNumberOfTiles
        progressLock.unlock()
        tableData.clearAllData()
        let section = tableData.createNewSection()
        section.footerText = isFinished && failedTiles == 0 ? localizedString("use_of_downloaded_map") : ""
        
        let progressRow = section.createNewRow()
        progressRow.cellType = OADownloadProgressBarCell.reuseIdentifier
        
        let numberOfTilesRow = section.createNewRow()
        numberOfTilesRow.cellType = OAValueTableViewCell.reuseIdentifier
        numberOfTilesRow.key = RowKey.numberOfTiles.rawValue
        numberOfTilesRow.title = localizedString("number_of_tiles")
        numberOfTilesRow.descr = " / \(numberOfTiles)"
        
        let downloadSizeRow = section.createNewRow()
        downloadSizeRow.cellType = OAValueTableViewCell.reuseIdentifier
        downloadSizeRow.key = RowKey.downloadSize.rawValue
        downloadSizeRow.title = localizedString("download_size")
        let size = ByteCountFormatter.string(fromByteCount: Int64(numberOfTiles) * estimatedTileSize, countStyle: .file)
        downloadSizeRow.descr = " / ~ \(size)"

        if failedTiles > 0 {
            let failedTilesRow = section.createNewRow()
            failedTilesRow.cellType = OAValueTableViewCell.reuseIdentifier
            failedTilesRow.key = RowKey.failedTiles.rawValue
            failedTilesRow.title = localizedString("osm_failed_uploads")
            if isFinished {
                let retryRow = section.createNewRow()
                retryRow.cellType = OAValueTableViewCell.reuseIdentifier
                retryRow.key = RowKey.retry.rawValue
                retryRow.title = localizedString("retry")
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        progressLock.lock()
        let downloadedTiles = downloadedNumberOfTiles
        let failedTiles = failedNumberOfTiles
        progressLock.unlock()
        let item = tableData.item(for: indexPath)
        if item.cellType == OADownloadProgressBarCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADownloadProgressBarCell.reuseIdentifier, for: indexPath) as! OADownloadProgressBarCell
            cell.selectionStyle = .none
            cell.separatorInset = .zero
            cell.backgroundColor = .groupBg
            cell.showLabels(true)
            if isFinished {
                cell.progressStatusLabel.text = localizedString(failedTiles > 0 ? "download_complete_with_errors" : "download_complete")
            } else {
                cell.progressStatusLabel.text = localizedString("downloading")
            }
            cell.progressStatusLabel.textColor = .textColorPrimary
            cell.progressValueLabel.textColor = .textColorPrimary
            cell.progressBarView.progressTintColor = .iconColorActive
            cell.progressBarView.trackTintColor = .customSeparator
            let progress = numberOfTiles > 0 ? Double(downloadedTiles) / Double(numberOfTiles) : 1
            cell.progressValueLabel.text = "\(Int(progress * 100))%"
            cell.progressBarView.progress = Float(progress)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
        cell.selectionStyle = .none
        cell.backgroundColor = .groupBg
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(false)
        cell.titleLabel.text = item.title
        cell.titleLabel.textColor = .textColorPrimary
        cell.accessibilityTraits = item.key == RowKey.retry.rawValue ? .button : []
        if item.key == RowKey.failedTiles.rawValue {
            cell.valueLabel.attributedText = nil
            cell.valueLabel.text = "\(failedTiles)"
            cell.valueLabel.textColor = .iconColorDisruptive
            return cell
        } else if item.key == RowKey.retry.rawValue {
            cell.titleLabel.textColor = .textColorActive
            cell.valueLabel.attributedText = nil
            cell.valueLabel.text = nil
            cell.selectionStyle = .default
            return cell
        }

        let done = item.key == RowKey.numberOfTiles.rawValue ? "\(downloadedTiles)" : ByteCountFormatter.string(fromByteCount: Int64(downloadedTiles) * estimatedTileSize, countStyle: .file)
        let value = NSMutableAttributedString(string: done, attributes: [.foregroundColor: UIColor.textColorPrimary])
        value.append(NSAttributedString(string: item.descr ?? "", attributes: [.foregroundColor: UIColor.textColorSecondary]))
        cell.valueLabel.attributedText = value
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .textColorSecondary
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        if tableData.item(for: indexPath).key == RowKey.retry.rawValue {
            retryFailedTiles()
        }
    }

    override func onLeftNavbarButtonPressed() {
        guard !isCancelled else { return }
        cancelDownload()
        navigationController?.popViewController(animated: true)
    }
    
    override func onBottomButtonPressed() {
        onLeftNavbarButtonPressed()
    }
    
    func onTileDownloaded(_ updateUI: Bool) {
        progressLock.lock()
        downloadedNumberOfTiles += 1
        let shouldUpdateUI = updateUI || downloadedNumberOfTiles + failedNumberOfTiles >= numberOfTiles
        progressLock.unlock()
        if shouldUpdateUI {
            updateProgress()
        }
    }
    
    func onTileFailed() {
        progressLock.lock()
        failedNumberOfTiles += 1
        progressLock.unlock()
        updateProgress()
    }

    private func retryFailedTiles() {
        guard isFinished, !isCancelled else { return }
        tileDownloader.delegate = nil
        tileDownloader.cancellAllRequests()
        tileDownloader = tileDownloader.forRetry()
        tileDownloader.delegate = self
        progressLock.lock()
        downloadedNumberOfTiles = 0
        failedNumberOfTiles = 0
        progressLock.unlock()
        isFinished = false
        generateData()
        updateBottomButtons()
        tableView.reloadData()
        tileDownloader.startDownload()
    }

    private func updateProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCancelled, !self.isFinished else { return }
            self.progressLock.lock()
            let isFinished = self.downloadedNumberOfTiles + self.failedNumberOfTiles >= self.numberOfTiles
            self.progressLock.unlock()
            if isFinished {
                self.onDownloadFinished()
            } else {
                self.generateData()
                self.tableView.reloadData()
            }
        }
    }
    
    private func onDownloadFinished() {
        isFinished = true
        progressLock.lock()
        let hasErrors = failedNumberOfTiles > 0
        progressLock.unlock()
        OsmAndApp.swiftInstance().mapSettingsChangeObservable.notifyEvent()
        generateData()
        updateBottomButtons()
        tableView.reloadData()
        UIAccessibility.post(notification: .announcement, argument: localizedString(hasErrors ? "download_complete_with_errors" : "map_downloaded"))
    }
    
    private func cancelDownload() {
        guard !isCancelled else { return }
        isCancelled = true
        if isFinished {
            OARootViewController.instance().mapPanel.targetHide()
        }
        
        tileDownloader.delegate = nil
        tileDownloader.cancellAllRequests()
    }
}
