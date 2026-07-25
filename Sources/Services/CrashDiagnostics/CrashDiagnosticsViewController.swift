//
//  CrashDiagnosticsViewController.swift
//  OsmAnd Maps
//

import UIKit

@objcMembers
final class CrashDiagnosticsViewController: UITableViewController {
    private var reports: [CrashReportSummary] = []
    private var reportIDToOpen: String?

    @objc(initWithReportIDToOpen:)
    init(reportIDToOpen: String? = nil) {
        self.reportIDToOpen = reportIDToOpen
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localizedString("crash_diagnostics")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CrashReportCell")
        tableView.backgroundColor = .groupTableViewBackground
        navigationItem.largeTitleDisplayMode = .never
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadReports),
            name: .crashDiagnosticsReportsDidChange,
            object: nil
        )
#if DEBUG
        let testItem = UIBarButtonItem(
            title: localizedString("crash_diagnostics_test"),
            style: .plain,
            target: nil,
            action: nil
        )
        testItem.menu = testCrashMenu()
        navigationItem.rightBarButtonItem = testItem
#endif
        reloadReports()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        configureLeftNavigationItem()
    }

    override func isNavbarVisible() -> Bool {
        true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let reportIDToOpen else { return }
        self.reportIDToOpen = nil
        showReport(reportID: reportIDToOpen)
    }

    @objc private func reloadReports() {
        reports = CrashDiagnosticsService.shared.pendingReports()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return max(reports.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 1 ? localizedString("crash_diagnostics_pending_reports") : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "CrashReportCell")
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.selectionStyle = .default

        if indexPath.section == 0 {
            cell.textLabel?.text = localizedString("crash_diagnostics_privacy_title")
            cell.detailTextLabel?.text = localizedString("crash_diagnostics_privacy_description")
            cell.imageView?.image = UIImage.templateImageNamed("ic_custom_file_info")
            cell.imageView?.tintColor = .iconColorDefault
            cell.selectionStyle = .none
            return cell
        }

        guard !reports.isEmpty else {
            cell.textLabel?.text = localizedString("crash_diagnostics_no_reports")
            cell.detailTextLabel?.text = nil
            cell.selectionStyle = .none
            return cell
        }

        let report = reports[indexPath.row]
        cell.textLabel?.text = title(for: report)
        cell.detailTextLabel?.text = "\(report.occurredAt) · \(stateTitle(report.uploadState))"
        cell.imageView?.image = UIImage.templateImageNamed("ic_custom_file_crashlog_send_outlined")
        cell.imageView?.tintColor = .iconColorDefault
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 1, !reports.isEmpty else { return }
        showReport(reportID: reports[indexPath.row].reportID)
    }

    private func showReport(reportID: String) {
        let viewController = CrashReportReviewViewController(reportID: reportID)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func configureLeftNavigationItem() {
        guard let navigationController,
              navigationController.viewControllers.first === self else {
            navigationItem.leftBarButtonItem = nil
            navigationItem.hidesBackButton = false
            return
        }
        let closeItem = UIBarButtonItem(
            title: localizedString("shared_string_close"),
            style: .plain,
            target: self,
            action: #selector(closeScreen)
        )
        closeItem.accessibilityLabel = localizedString("shared_string_close")
        navigationItem.leftBarButtonItem = closeItem
    }

    @objc private func closeScreen() {
        dismiss(animated: true)
    }

    private func title(for report: CrashReportSummary) -> String {
        switch report.kind {
        case .hang:
            return localizedString("crash_diagnostics_hang")
        case .cpuException:
            return localizedString("crash_diagnostics_cpu")
        case .diskWriteException:
            return localizedString("crash_diagnostics_disk")
        case .nonFatal:
            return localizedString("crash_diagnostics_non_fatal")
        default:
            return localizedString("crash_diagnostics_crash")
        }
    }

    private func stateTitle(_ state: CrashUploadState) -> String {
        switch state {
        case .pending:
            return localizedString("crash_diagnostics_not_sent")
        case .approved:
            return localizedString("crash_diagnostics_approved")
        case .rejected:
            return localizedString("crash_diagnostics_rejected")
        }
    }

#if DEBUG
    private func testCrashMenu() -> UIMenu {
        let actions: [(String, Selector)] = [
            ("Objective-C", #selector(triggerObjectiveCException)),
            ("C++", #selector(triggerCPPException)),
            ("SIGABRT", #selector(triggerSignalCrash)),
            ("Invalid memory", #selector(triggerInvalidMemoryAccess)),
        ]
        return UIMenu(
            title: localizedString("crash_diagnostics_test_warning"),
            children: actions.map { title, selector in
                UIAction(title: title, attributes: .destructive) { [weak self] _ in
                    self?.confirmTestCrash(title: title, selector: selector)
                }
            }
        )
    }

    private func confirmTestCrash(title: String, selector: Selector) {
        let alert = UIAlertController(
            title: localizedString("crash_diagnostics_test"),
            message: localizedString("crash_diagnostics_test_confirmation"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: title, style: .destructive) { [weak self] _ in
            _ = self?.perform(selector)
        })
        present(alert, animated: true)
    }

    @objc private func triggerObjectiveCException() {
        OACrashDiagnosticsKSCrashBridge.triggerObjectiveCException()
    }

    @objc private func triggerCPPException() {
        OACrashDiagnosticsKSCrashBridge.triggerCPPException()
    }

    @objc private func triggerSignalCrash() {
        OACrashDiagnosticsKSCrashBridge.triggerSignalCrash()
    }

    @objc private func triggerInvalidMemoryAccess() {
        OACrashDiagnosticsKSCrashBridge.triggerInvalidMemoryAccess()
    }
#endif
}

private final class CrashReportReviewViewController: UIViewController, UIDocumentPickerDelegate {
    private let reportID: String
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let laterButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var reportJSON: String?
    private var temporaryExportURL: URL?

    init(reportID: String) {
        self.reportID = reportID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localizedString("crash_diagnostics_review")
        view.backgroundColor = .systemBackground
        configureTextView()
        configureButtons()
        loadReport()
        configureExportMenu()
    }

    private func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.accessibilityLabel = localizedString("crash_diagnostics_payload")
        view.addSubview(textView)
    }

    private func configureButtons() {
        configureButton(sendButton, title: localizedString("crash_diagnostics_send_once"), action: #selector(sendReport))
        configureButton(deleteButton, title: localizedString("shared_string_delete"), action: #selector(confirmDelete))
        configureButton(laterButton, title: localizedString("crash_diagnostics_later"), action: #selector(close))
        deleteButton.tintColor = .systemRed
        sendButton.isHidden = !CrashDiagnosticsService.shared.canUpload

        let stack = UIStackView(arrangedSubviews: [sendButton, deleteButton, laterButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8
        view.addSubview(stack)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            stack.heightAnchor.constraint(equalToConstant: 48),
            activityIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
        ])
    }

    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    private func loadReport() {
        do {
            let json = try CrashDiagnosticsService.shared.prettyPrintedReport(reportID: reportID)
            reportJSON = json
            textView.text = json
        } catch {
            textView.text = localizedString("crash_diagnostics_report_unavailable")
            sendButton.isEnabled = false
            deleteButton.isEnabled = false
        }
    }

    private func configureExportMenu() {
        guard reportJSON != nil else { return }
        let copyAction = UIAction(
            title: localizedString("crash_diagnostics_copy_json"),
            image: UIImage(systemName: "doc.on.doc")
        ) { [weak self] _ in
            self?.copyJSON()
        }
        let saveAction = UIAction(
            title: localizedString("crash_diagnostics_save_json"),
            image: UIImage(systemName: "folder")
        ) { [weak self] _ in
            self?.saveJSONFile()
        }
        let exportItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            menu: UIMenu(children: [copyAction, saveAction])
        )
        exportItem.accessibilityLabel = localizedString("shared_string_export")
        navigationItem.rightBarButtonItem = exportItem
    }

    private func copyJSON() {
        guard let reportJSON else { return }
        UIPasteboard.general.string = reportJSON
        navigationItem.prompt = localizedString("crash_diagnostics_copied")
        UIAccessibility.post(
            notification: .announcement,
            argument: localizedString("crash_diagnostics_copied")
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.navigationItem.prompt = nil
        }
    }

    private func saveJSONFile() {
        guard let reportJSON, let data = reportJSON.data(using: .utf8) else { return }
        removeTemporaryExport()

        let safeReportID = reportID.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let filenameID = safeReportID.isEmpty ? "report" : String(safeReportID.prefix(64))
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("OsmAnd-Crash-Report-\(filenameID).json")
        do {
            try data.write(
                to: exportURL,
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
            )
            temporaryExportURL = exportURL
            let documentPicker = UIDocumentPickerViewController(
                forExporting: [exportURL],
                asCopy: true
            )
            documentPicker.delegate = self
            present(documentPicker, animated: true)
        } catch {
            showExportError(error)
        }
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        removeTemporaryExport()
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        removeTemporaryExport()
    }

    private func removeTemporaryExport() {
        guard let temporaryExportURL else { return }
        try? FileManager.default.removeItem(at: temporaryExportURL)
        self.temporaryExportURL = nil
    }

    private func showExportError(_ error: Error) {
        let alert = UIAlertController(
            title: localizedString("shared_string_error"),
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
        present(alert, animated: true)
    }

    @objc private func sendReport() {
        setSending(true)
        CrashDiagnosticsService.shared.approveAndSend(reportID: reportID) { [weak self] result in
            guard let self else { return }
            self.setSending(false)
            switch result {
            case .success:
                self.finish()
            case let .failure(error):
                let alert = UIAlertController(
                    title: localizedString("shared_string_error"),
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    @objc private func confirmDelete() {
        let alert = UIAlertController(
            title: localizedString("crash_diagnostics_delete_title"),
            message: localizedString("crash_diagnostics_delete_description"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            CrashDiagnosticsService.shared.delete(reportID: self.reportID)
            self.finish()
        })
        present(alert, animated: true)
    }

    @objc private func close() {
        finish()
    }

    private func setSending(_ sending: Bool) {
        sendButton.setTitle(sending ? nil : localizedString("crash_diagnostics_send_once"), for: .normal)
        sendButton.isEnabled = !sending
        deleteButton.isEnabled = !sending
        laterButton.isEnabled = !sending
        sending ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }

    private func finish() {
        if let navigationController, navigationController.viewControllers.first != self {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
