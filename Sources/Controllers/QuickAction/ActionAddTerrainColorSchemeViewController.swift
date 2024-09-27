//
//  ActionAddTerrainColorSchemeViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 26.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc protocol ActionAddTerrainColorSchemeDelegate: AnyObject {
    func onTerrainsSelected(_ items: [[String: Any]])
}

@objcMembers
final class ActionAddTerrainColorSchemeViewController: OABaseNavbarViewController {

    weak var delegate: ActionAddTerrainColorSchemeDelegate?

    private var data = [(String, [TerrainMode])]()
    private var initialPalettes: [String]

    // MARK: - Initialize

    init(withPalettes: [String]) {
        self.initialPalettes = withPalettes
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.isEditing = true
    }

    // MARK: - Base UI

    override func getTitle() -> String {
        localizedString("srtm_color_scheme")
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(localizedString("shared_string_done"),
                                 iconName: nil,
                                 action: #selector(onRightNavbarButtonPressed),
                                 menu: nil)]
    }

    // MARK: - Table data

    override func generateData() {
        var data = [(String, [TerrainMode])]()
        for type in TerrainType.allCases {
            var header = ""
            var modes = [TerrainMode]()
            for mode in TerrainMode.values where mode.type == type {
                modes.append(mode)
                if header.isEmpty {
                    header = mode.getDescription()
                }
            }
            if !modes.isEmpty {
                modes.sort {
                    let name0 = $0.getDefaultDescription()
                    let name1 = $1.getDefaultDescription()
                    if $0.isDefaultMode() {
                        return true
                    } else if $1.isDefaultMode() {
                        return false
                    } else {
                        let isDuplicate0 = $0.isDefaultDuplicatedMode()
                        let isDuplicate1 = $1.isDefaultDuplicatedMode()
                        if isDuplicate0 && isDuplicate1 {
                            return name0 < name1
                        } else if isDuplicate0 {
                            return true
                        } else if isDuplicate1 {
                            return false
                        }
                    }
                    return name0 < name1
                }
                data.append((header, modes))
            }
        }
        data.sort { $0.0 < $1.0 }
        self.data = data
    }

    override func sectionsCount() -> Int {
        data.count
    }

    override func getTitleForHeader(_ section: Int) -> String {
        data[section].0
    }

    override func rowsCount(_ section: Int) -> Int {
        data[section].1.count
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        let mode = data[indexPath.section].1[indexPath.row]

        cell.leftIconView.layer.cornerRadius = 3
        if let colorPalette = ColorPaletteHelper
            .shared
            .getGradientColorPalette(mode.getMainFile()) {
            PaletteCollectionHandler.applyGradient(to: cell.leftIconView,
                                                   with: colorPalette)
            cell.descriptionLabel.text = PaletteCollectionHandler.createDescriptionForPalette(colorPalette)
        }

        cell.titleLabel.text = mode.getDefaultDescription()
        cell.accessibilityLabel = cell.titleLabel.text
        let isSelected = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false
        let key = mode.getKeyName()
        if initialPalettes.contains(key) {
            tableView.selectRow(at: indexPath,
                                animated: true,
                                scrollPosition: .none)
            initialPalettes.removeAll { $0 == key }
        }
        cell.accessibilityValue = localizedString(isSelected ? "shared_string_selected" : "shared_string_not_selected")
        return cell
    }

    // MARK: - Selectors

    override func onRightNavbarButtonPressed() {
        var items = [[String: Any]]()
        if let selectedItems = tableView.indexPathsForSelectedRows {
            for item in selectedItems {
                let mode = data[item.section].1[item.row]
                if let colorPalette = ColorPaletteHelper
                    .shared
                    .getGradientColorPalette(mode.getMainFile()) {
                    items.append([
                        "title": mode.getDefaultDescription(),
                        "desc": PaletteCollectionHandler.createDescriptionForPalette(colorPalette),
                        "colorPalette": colorPalette,
                        "palette": mode.getKeyName()
                    ])
                }
            }
        }
        delegate?.onTerrainsSelected(items)
        dismiss()
    }
}
