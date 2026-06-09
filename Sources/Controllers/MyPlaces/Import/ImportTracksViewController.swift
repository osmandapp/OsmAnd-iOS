//
//  ImportTracksViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 08.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

final class ImportTrackItem: Hashable {
    let index: Int
    let name: String
    let gpxFile: GpxFile          // один track из исходного файла
    var selectedPoints: [WptPt] = []
    var suggestedPoints: [WptPt] = []

    // preview — позже
    // var previewImage: UIImage?
    
    init(index: Int, name: String, gpxFile: GpxFile, selectedPoints: [WptPt], suggestedPoints: [WptPt]) {
        self.index = index
        self.name = name
        self.gpxFile = gpxFile
        self.selectedPoints = selectedPoints
        self.suggestedPoints = suggestedPoints
    }

    static func == (lhs: ImportTrackItem, rhs: ImportTrackItem) -> Bool {
        lhs.index == rhs.index
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}

@objc protocol ImportTracksViewControllerDelegate: AnyObject {
    @objc optional func importTracksViewControllerDidFinishImport(_ controller: ImportTracksViewController, success: Bool)
    @objc optional func importTracksViewController(_ controller: ImportTracksViewController, didSaveTrack success: Bool, gpxFile: GpxFile)
}

final class ImportTracksViewController: OABaseButtonsViewController {
    weak var delegate: ImportTracksViewControllerDelegate?
    
    private let gpxFile: GpxFile
    private let fileName: String
    private var selectedFolderPath: String
    private let importURL: URL?
    private let openGpxView: Bool
    private var importCompletion: ((Bool) -> Void)?
    
    private var trackItems: [ImportTrackItem] = []
    private var selectedTracks: Set<ImportTrackItem> = []
    private var isCollectingTracks = false
    private var isSavingTracks = false
    private var collectTracksTask: CollectTracksTask?
    
    //UI
    private let progressStackView = UIStackView()
    private let progressIndicator = UIActivityIndicatorView(style: .medium)
    private let progressLabel = UILabel()
    
    // MARK: - Init
    
    @objc(initWithGpxFile:fileName:selectedFolderPath:importURL:openGpxView:completion:)
    init(gpxFile: GpxFile, fileName: String, selectedFolderPath: String?, importURL: URL?, openGpxView: Bool, completion: ((Bool) -> Void)?) {
        self.gpxFile = gpxFile
        self.fileName = fileName
        self.importURL = importURL
        self.openGpxView = openGpxView
        self.importCompletion = completion
        
        if let selectedFolderPath, !selectedFolderPath.isEmpty {
            self.selectedFolderPath = selectedFolderPath
        } else {
            let app = OsmAndApp.swiftInstance()
            self.selectedFolderPath = (app?.gpxPath as? String)?.appending("/import") ?? ""
        }
        super.init()
    }
    
    @available(*, unavailable)
    override init() {
        fatalError("Use init(gpxFile:fileName:selectedFolderPath:importURL:openGpxView:completion:)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgressView()
        collectTracks()
    }
    
    // MARK: - Table
    
    override func generateData() {
        tableData.clearAllData()
        // TODO: section 0 info, section 1 tracks, section 2 folder
    }
    
    // MARK: - NavBar
    
    override func getTitle() -> String! {
        localizedString("import_tracks")
    }
    
    override func getCustomIconForLeftNavbarButton() -> UIImage! {
        .templateImageNamed("ic_navbar_close")?.withTintColor(.label)
    }
    
    override func onLeftNavbarButtonPressed() {
        showExitConfirmation()
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem]! {
        guard !trackItems.isEmpty, !isCollectingTracks, !isSavingTracks else {
            return nil
        }
        let allSelected = selectedTracks.count == trackItems.count
        let title = localizedString(allSelected ? "shared_string_deselect_all" : "shared_string_select_all")
        guard let button = OABaseNavbarViewController.createRightNavbarButton(title, icon: nil, color: .label,
                                                                              action: #selector(onSelectAllNavbarButtonPressed),
                                                                              target: self, menu: nil) else {
            return []
        }
        button.accessibilityLabel = title
        return [button]
    }
    
    override func updateNavbar() {
        super.updateNavbar()
        getLeftNavbarButton().tintColor = .label
    }
    
    // MARK: - Bottom buttons
    
    override func getTopButtonTitle() -> String! {
        let selected = selectedTracks.count
        let total = trackItems.count
        return "\(localizedString("shared_string_import")) \(selected)/\(total)"
    }

    override func isBottomSeparatorVisible() -> Bool {
        false
    }
    
    override func onTopButtonPressed() {
        importSelectedTracks()
    }
    
    // MARK: - Setup
    
    private func setupProgressView() {
        progressStackView.translatesAutoresizingMaskIntoConstraints = false
        progressStackView.axis = .vertical
        progressStackView.alignment = .center
        progressStackView.spacing = 16
        progressStackView.addArrangedSubview(progressIndicator)
        progressStackView.addArrangedSubview(progressLabel)
        view.addSubview(progressStackView)

        progressLabel.font = .preferredFont(forTextStyle: .subheadline)
        progressLabel.textColor = .textColorSecondary
        progressLabel.textAlignment = .center
        progressLabel.numberOfLines = 0
        progressLabel.adjustsFontForContentSizeCategory = true
        NSLayoutConstraint.activate([
            progressStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func updateProgress() {
        let progressVisible = isCollectingTracks || isSavingTracks
        if isCollectingTracks {
            progressLabel.text = localizedString("reading_file") + localizedString("shared_string_ellipsis")
        } else if isSavingTracks {
            progressLabel.text = String(format: localizedString("importing_from"), fileName)
        }
        if progressVisible {
            progressIndicator.startAnimating()
        } else {
            progressIndicator.stopAnimating()
        }
        progressStackView.isHidden = !progressVisible
        tableView.isHidden = progressVisible
        topButton.isHidden = progressVisible
        separatorBottomView.isHidden = progressVisible
        setupNavbarButtons()
    }
    
    private func collectTracks() {
        collectTracksTask = CollectTracksTask(
            gpxFile: gpxFile,
            fileName: fileName,
            listener: self
        )
        collectTracksTask?.execute()
    }

    // MARK: - Actions
    
    @objc private func onSelectAllNavbarButtonPressed() {
        if selectedTracks.count == trackItems.count {
            selectedTracks.removeAll()
        } else {
            selectedTracks = Set(trackItems)
        }
        updateButtonsState()
        tableView.reloadData()
    }
    
    private func importSelectedTracks() {
        // SaveTracksTask
    }
    
    @objc
    private func showExitConfirmation() {
        let alert = UIAlertController(
            title: localizedString("import_tracks_cancel_title"),
            message: localizedString("import_tracks_cancel_descr"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: localizedString("shared_string_continue"),
            style: .default
        ))
        alert.addAction(UIAlertAction(
            title: localizedString("shared_string_close"),
            style: .destructive
        ) { [weak self] _ in
            self?.collectTracksTask?.cancelled = true
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func updateButtonsState() {
        topButton.isEnabled = !selectedTracks.isEmpty
        updateBottomButtons()
    }
}

// MARK: - CollectTracksListener

extension ImportTracksViewController: CollectTracksListener {
    func tracksCollectionStarted() {
        isCollectingTracks = true
        updateProgress()
    }

    func tracksCollectionFinished(_ items: [ImportTrackItem]) {
        collectTracksTask = nil
        isCollectingTracks = false
        trackItems = items
        selectedTracks = Set(items)
        updateProgress()
        updateButtonsState()
        generateData()
        tableView.reloadData()
    }
}
