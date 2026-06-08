import UIKit
import OsmAndShared

protocol OrganizeByStepSizeDelegate: AnyObject {
    func onStepSizeChanged()
}

final class OrganizeByStepSizeViewController: OABaseNavbarViewController {

    // MARK: - Private Types

    private enum Section: Int {
        case main
    }

    private enum RowKey: String {
        case slider
    }

    private enum DataKey: String {
        case stepValue
    }

    // MARK: - Instance Properties

    private let smartFolder: SmartFolder
    private let type: OrganizeByType
    private let displayUnits: any MeasurementUnit
    private let stepRange: Limits
    private var currentDisplayValue: Float
    private let initialParams: OrganizeByParams?
    private var isExplicitlyDismissed = false
    private var previewWorkItem: DispatchWorkItem?

    private static let previewDebounceInterval: TimeInterval = 0.15

    weak var stepDelegate: OrganizeByStepSizeDelegate?

    // MARK: - Initializers

    init(smartFolder: SmartFolder, type: OrganizeByType, originalParams: OrganizeByParams?) {
        self.smartFolder = smartFolder
        self.type = type
        self.displayUnits = type.getDisplayUnits()
        guard let range = type.stepRange else {
            fatalError("OrganizeByStepSizeViewController requires a range-related OrganizeByType")
        }
        self.stepRange = range
        self.initialParams = originalParams

        let existingBase: Double
        if let rangeParams = smartFolder.organizeByParams as? OrganizeByRangeParams {
            existingBase = rangeParams.stepSize
        } else {
            existingBase = type.getDefaultStepInBaseUnits()
        }
        let rawDisplayValue = Float(Int(type.getDisplayUnits().fromBase(value: existingBase)))
        let minDisplayValue = (range.min as? NSNumber).map { Float(truncating: $0) } ?? rawDisplayValue
        let maxDisplayValue = (range.max as? NSNumber).map { Float(truncating: $0) } ?? rawDisplayValue
        self.currentDisplayValue = min(max(rawDisplayValue, minDisplayValue), maxDisplayValue)

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.presentationController?.delegate = self
    }

    override func registerCells() {
        addCell(TopBottomValuesSliderTableViewCell.reuseIdentifier)
    }

    override func getTitle() -> String {
        localizedString("set_step_size")
    }

    override func getTableHeaderDescription() -> String { "" }

    override func getTableHeaderDescriptionAttr() -> NSAttributedString? {
        let text = localizedString("set_step_size_summary")
        return NSAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.textColorSecondary
        ])
    }

    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onClosePressed))
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func systemRightBarButtonItems() -> [UIBarButtonItem]? {
        let isApplicable = !type.isPro || OAIAPHelper.isOsmAndProAvailable()
        if isApplicable {
            return [NavbarBlueButton.circleBarButtonItem(
                image: .templateImageNamed("ic_checkmark_default"),
                target: self,
                action: #selector(onConfirmPressed)
            )]
        } else {
            return [NavbarBlueButton.pillBarButtonItem(
                title: localizedString("shared_string_unlock"),
                target: self,
                action: #selector(onUnlockPressed)
            )]
        }
    }

    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let row = section.createNewRow()
        row.cellType = TopBottomValuesSliderTableViewCell.reuseIdentifier
        row.key = RowKey.slider.rawValue
        row.title = localizedString("shared_string_step")
        row.setObj(currentDisplayValue as Any, forKey: DataKey.stepValue.rawValue)
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        guard item.key == RowKey.slider.rawValue,
              let cell = tableView.dequeueReusableCell(
                withIdentifier: TopBottomValuesSliderTableViewCell.reuseIdentifier
              ) as? TopBottomValuesSliderTableViewCell,
              let value = item.obj(forKey: DataKey.stepValue.rawValue) as? Float else { return nil }

        let unitSymbol = displayUnits.getSymbol()
        let minVal = (stepRange.min as? NSNumber).map { Float(truncating: $0) } ?? 0
        let maxVal = (stepRange.max as? NSNumber).map { Float(truncating: $0) } ?? 100

        cell.selectionStyle = .none
        cell.topRightLabelVisibility(true)
        cell.topRightButtonVisibility(false)
        cell.sliderValuesVisibility(true)

        cell.topLeftLabel.text = item.title
        cell.topLeftLabel.font = .preferredFont(forTextStyle: .body)
        cell.topRightLabel.text = "\(Int(value)) \(unitSymbol)"
        cell.topRightLabel.textColor = .textColorSecondary

        cell.slider.minimumValue = minVal
        cell.slider.maximumValue = maxVal
        cell.slider.value = value
        cell.slider.tintColor = .systemBlue
        cell.slider.maximumTrackTintColor = .sliderLineBg
        cell.slider.removeTarget(self, action: nil, for: .valueChanged)
        cell.slider.addTarget(self, action: #selector(onSliderChanged(_:)), for: .valueChanged)

        cell.bottomLeftLabel.text = "\(Int(minVal)) \(unitSymbol)"
        cell.bottomLeftLabel.textColor = .textColorSecondary
        cell.bottomRightLabel.text = "\(Int(maxVal)) \(unitSymbol)"
        cell.bottomRightLabel.textColor = .textColorSecondary

        return cell
    }

    private func makeCurrentParams() -> OrganizeByRangeParams {
        let stepInBase = displayUnits.toBase(value: Double(Int(currentDisplayValue)))
        return OrganizeByRangeParams(type: type, stepSize: stepInBase)
    }

    private func applyStepInMemory() {
        smartFolder.setOrganizeByParams(organizeByParams: makeCurrentParams())
    }

    private func persistCurrentStep() {
        let params = makeCurrentParams()
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
        smartFolder.setOrganizeByParams(organizeByParams: params)
    }

    private func schedulePreviewUpdate() {
        previewWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.applyStepInMemory()
            self.stepDelegate?.onStepSizeChanged()
        }
        previewWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.previewDebounceInterval, execute: workItem)
    }

    private func performCancel() {
        previewWorkItem?.cancel()
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: initialParams)
        smartFolder.setOrganizeByParams(organizeByParams: initialParams)
        stepDelegate?.onStepSizeChanged()
    }

    @objc private func onSliderChanged(_ sender: UISlider) {
        let rounded = sender.value.rounded()
        sender.value = rounded
        currentDisplayValue = rounded
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.main.rawValue)) as? TopBottomValuesSliderTableViewCell {
            cell.topRightLabel.text = "\(Int(rounded)) \(displayUnits.getSymbol())"
        }
        schedulePreviewUpdate()
    }

    @objc private func onConfirmPressed() {
        isExplicitlyDismissed = true
        previewWorkItem?.cancel()
        persistCurrentStep()
        stepDelegate?.onStepSizeChanged()
        dismiss(animated: true)
    }

    @objc private func onClosePressed() {
        isExplicitlyDismissed = true
        performCancel()
        dismiss(animated: true)
    }

    @objc private func onUnlockPressed() {
        guard let navigationController else { return }
        OAChoosePlanHelper.showChoosePlanScreen(
            with: OAFeature.advanced_WIDGETS(),
            navController: navigationController
        )
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension OrganizeByStepSizeViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard !isExplicitlyDismissed else { return }
        performCancel()
    }
}
