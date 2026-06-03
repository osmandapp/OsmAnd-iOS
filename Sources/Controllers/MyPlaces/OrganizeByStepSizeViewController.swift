import UIKit
import OsmAndShared

protocol OrganizeByStepSizeDelegate: AnyObject {
    func onStepSizeChanged()
}

final class OrganizeByStepSizeViewController: OABaseNavbarViewController {

    // MARK: - Private Types

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
    private var changesApplied = false

    weak var stepDelegate: OrganizeByStepSizeDelegate?

    // MARK: - Initializers

    init(smartFolder: SmartFolder, type: OrganizeByType) {
        self.smartFolder = smartFolder
        self.type = type
        self.displayUnits = type.getDisplayUnits()
        self.stepRange = type.stepRange!
        self.initialParams = smartFolder.organizeByParams

        let existingBase: Double
        if let rangeParams = smartFolder.organizeByParams as? OrganizeByRangeParams {
            existingBase = rangeParams.stepSize
        } else {
            existingBase = type.getDefaultStepInBaseUnits()
        }
        self.currentDisplayValue = Float(type.getDisplayUnits().fromBase(value: existingBase))

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        if let button = navigationItem.leftBarButtonItem?.customView as? UIButton {
            button.tintColor = .textColorPrimary
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: #selector(onClosePressed), for: .touchUpInside)
        }
    }

    override func registerCells() {
        addCell(TopBottomValuesSliderTableViewCell.reuseIdentifier)
    }

    override func getTitle() -> String {
        localizedString("set_step_size")
    }

    override func getTableHeaderDescription() -> String {
        localizedString("set_step_size_summary")
    }

    override func getCustomIconForLeftNavbarButton() -> UIImage? {
        .templateImageNamed("ic_navbar_close")
    }

    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let proAvailable = OAIAPHelper.isOsmAndProAvailable()
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        if proAvailable {
            config.image = .templateImageNamed("ic_checkmark_default")
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        } else {
            config.title = localizedString("shared_string_unlock")
        }
        let button = UIButton(configuration: config)
        button.addTarget(
            self,
            action: proAvailable ? #selector(onConfirmPressed) : #selector(onUnlockPressed),
            for: .touchUpInside
        )
        button.sizeToFit()
        return [UIBarButtonItem(customView: button)]
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
        cell.slider.tintColor = .iconColorActive
        cell.slider.maximumTrackTintColor = .sliderLineBg
        cell.slider.removeTarget(self, action: nil, for: .valueChanged)
        cell.slider.addTarget(self, action: #selector(onSliderChanged(_:)), for: .valueChanged)

        cell.bottomLeftLabel.text = "\(Int(minVal)) \(unitSymbol)"
        cell.bottomLeftLabel.textColor = .textColorSecondary
        cell.bottomRightLabel.text = "\(Int(maxVal)) \(unitSymbol)"
        cell.bottomRightLabel.textColor = .textColorSecondary

        return cell
    }

    private func saveCurrentStep() {
        let stepInBase = displayUnits.toBase(value: Double(currentDisplayValue))
        let params = OrganizeByRangeParams(type: type, stepSize: stepInBase)
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: params)
    }

    @objc private func onSliderChanged(_ sender: UISlider) {
        currentDisplayValue = sender.value
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TopBottomValuesSliderTableViewCell {
            cell.topRightLabel.text = "\(Int(sender.value)) \(displayUnits.getSymbol())"
        }
        saveCurrentStep()
        stepDelegate?.onStepSizeChanged()
    }

    @objc private func onConfirmPressed() {
        changesApplied = true
        saveCurrentStep()
        dismiss(animated: true) { [weak self] in
            self?.stepDelegate?.onStepSizeChanged()
        }
    }

    @objc private func onClosePressed() {
        SharedLibSmartFolderHelper.shared.setOrganizeByParams(folderId: smartFolder.getId(), params: initialParams)
        dismiss(animated: true) { [weak self] in
            self?.stepDelegate?.onStepSizeChanged()
        }
    }

    @objc private func onUnlockPressed() {
        guard let navigationController else { return }
        OAChoosePlanHelper.showChoosePlanScreen(
            with: OAFeature.advanced_WIDGETS(),
            navController: navigationController
        )
    }
}
