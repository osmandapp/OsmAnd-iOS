//
//  DownloadMapProgressViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 19.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class DownloadMapProgressViewController: OABaseButtonsViewController, OATileDownloadDelegate {
    private let tileDownloader: OAMapTileDownloader
    private let numberOfTiles: Int
    private let estimatedTileSize: Int64 = 12000
    private let progressLock = NSLock()
    private var downloadedNumberOfTiles = 0
    private var isDownloaded = false
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
        localizedString(isDownloaded ? "shared_string_close" : "shared_string_cancel")
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
        tableData.clearAllData()
        let section = tableData.createNewSection()
        section.footerText = isDownloaded ? localizedString("use_of_downloaded_map") : ""
        
        let progressRow = section.createNewRow()
        progressRow.cellType = OADownloadProgressBarCell.reuseIdentifier
        
        let numberOfTilesRow = section.createNewRow()
        numberOfTilesRow.cellType = OAValueTableViewCell.reuseIdentifier
        numberOfTilesRow.key = "number_of_tiles"
        numberOfTilesRow.title = localizedString("number_of_tiles")
        numberOfTilesRow.descr = " / \(numberOfTiles)"
        
        let downloadSizeRow = section.createNewRow()
        downloadSizeRow.cellType = OAValueTableViewCell.reuseIdentifier
        downloadSizeRow.key = "download_size"
        downloadSizeRow.title = localizedString("download_size")
        let size = ByteCountFormatter.string(fromByteCount: Int64(numberOfTiles) * estimatedTileSize, countStyle: .file)
        downloadSizeRow.descr = " / ~ \(size)"
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        progressLock.lock()
        let downloadedTiles = downloadedNumberOfTiles
        progressLock.unlock()
        let item = tableData.item(for: indexPath)
        if item.cellType == OADownloadProgressBarCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADownloadProgressBarCell.reuseIdentifier, for: indexPath) as! OADownloadProgressBarCell
            cell.selectionStyle = .none
            cell.separatorInset = .zero
            cell.backgroundColor = .groupBg
            cell.showLabels(true)
            cell.progressStatusLabel.text = localizedString("downloading")
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
        let done = item.key == "number_of_tiles" ? "\(downloadedTiles)" : ByteCountFormatter.string(fromByteCount: Int64(downloadedTiles) * estimatedTileSize, countStyle: .file)
        let value = NSMutableAttributedString(string: done, attributes: [.foregroundColor: UIColor.textColorPrimary])
        value.append(NSAttributedString(string: item.descr ?? "", attributes: [.foregroundColor: UIColor.textColorSecondary]))
        cell.valueLabel.attributedText = value
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .textColorSecondary
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
        let shouldUpdateUI = updateUI || downloadedNumberOfTiles == numberOfTiles
        progressLock.unlock()
        if shouldUpdateUI {
            updateProgress()
        }
    }
    
    private func updateProgress() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isCancelled, !self.isDownloaded else { return }
            self.progressLock.lock()
            let isFinished = self.downloadedNumberOfTiles == self.numberOfTiles
            self.progressLock.unlock()
            if isFinished {
                self.onDownloadFinished()
            } else {
                self.tableView.reloadSections(IndexSet(integer: 0), with: .none)
            }
        }
    }
    
    private func onDownloadFinished() {
        isDownloaded = true
        OsmAndApp.swiftInstance().mapSettingsChangeObservable.notifyEvent()
        generateData()
        updateBottomButtons()
        tableView.reloadData()
    }
    
    private func cancelDownload() {
        guard !isCancelled else { return }
        isCancelled = true
        if isDownloaded {
            OARootViewController.instance().mapPanel.targetHide()
        }
        
        tileDownloader.cancellAllRequests()
    }
}
