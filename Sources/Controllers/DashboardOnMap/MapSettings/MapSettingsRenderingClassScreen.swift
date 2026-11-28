//
//  MapSettingsRenderingClassScreen.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

// The child rendering classes of one style class (e.g. the cycling network levels), each shown or hidden on the map
@objcMembers
final class MapSettingsRenderingClassScreen: NSObject, OAMapSettingsScreen {
    var settingsScreen: EMapSettingsScreen = .renderingClass
    var vwController: OADashboardViewController?
    var tblView: UITableView?
    var title: String?
    var isOnlineMapSource = false
    var tableData: [Any]?

    private let styleSettings = OAMapStyleSettings.sharedInstance()
    private let parentClassName: String
    private var renderingClasses: [OAMapStyleRenderingClass] = []

    init(table tableView: UITableView, viewController: OADashboardViewController) {
        fatalError("init(table:viewController:)")
    }

    init(table tableView: UITableView, viewController: OADashboardViewController, param: Any) {
        parentClassName = param as? String ?? ""
        super.init()
        tblView = tableView
        vwController = viewController
        title = styleSettings?.getRenderingClass(parentClassName)?.title
    }

    func setupView() {
        tblView?.register(UINib(nibName: OASwitchTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASwitchTableViewCell.reuseIdentifier)
        initData()
    }

    func initData() {
        renderingClasses = styleSettings?.getRenderingClassChildren(parentClassName) ?? []
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        renderingClasses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let renderingClass = renderingClasses[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
        cell.descriptionVisibility(false)
        cell.leftIconVisibility(false)
        cell.titleLabel.text = renderingClass.title
        cell.switchView.setOn(styleSettings?.isRenderingClassEnabled(renderingClass) ?? true, animated: false)
        cell.switchView.tag = indexPath.row
        cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
        cell.switchView.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        nil
    }

    @objc private func onSwitchChanged(_ sender: UISwitch) {
        styleSettings?.setRenderingClass(renderingClasses[sender.tag], enabled: sender.isOn)
    }
}
