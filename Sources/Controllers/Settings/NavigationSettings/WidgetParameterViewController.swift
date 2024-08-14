//
//  WidgetParameterViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 26.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetParameterViewController)
@objcMembers
class WidgetParameterViewController: OABaseNavbarViewController {
    
    var screenTitle: String!
    var appMode: OAApplicationMode!
    var delegate: WidgetStateDelegate?
    var pref: OACommonPreference?
    var widgetConfigurationSelectedValue: String?
    var onWidgetConfigurationParamsAction: ((String?) -> Void)? = nil

    //MARK: - Base UI

    override func getTitle() -> String! {
        screenTitle
    }

    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    //MARK: - Table data

    override func hideFirstHeader() -> Bool {
        true
    }

    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        if (item.cellType == OASimpleTableViewCell.getIdentifier()) {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.tintColor = UIColor.iconColorActive
            }
            if let cell = cell {
                if let imageName = item.iconName, !imageName.isEmpty {
                    cell.leftIconVisibility(true)
                    cell.leftIconView.image = UIImage(named: imageName)
                } else {
                    cell.leftIconVisibility(false)
                }
                if let descr = item.descr, !descr.isEmpty {
                    cell.descriptionVisibility(true)
                    cell.descriptionLabel.text = descr
                } else {
                    cell.descriptionVisibility(false)
                }
                let selectedVal: String?
                if let widgetConfigurationSelectedValue {
                    selectedVal = widgetConfigurationSelectedValue
                } else {
                    selectedVal = pref?.toStringValue(appMode)
                }
                let val = stringValue(from: item.obj(forKey: "value"))

                cell.accessoryType = selectedVal == val ? .checkmark : .none
                cell.titleLabel.text = item.title
            }
            return cell
        } else if (item.cellType == OASegmentSliderTableViewCell.getIdentifier()) {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASegmentSliderTableViewCell.getIdentifier()) as? OASegmentSliderTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASegmentSliderTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASegmentSliderTableViewCell
            }
            if let cell = cell {
                if let values = item.obj(forKey: "values") as? [Int: String] {
                    let long: Int
                    if let prefLong = pref as? OACommonLong {
                        long = Int(prefLong.get(appMode))
                    } else {
                        long = Int(widgetConfigurationSelectedValue ?? "0")!
                    }
  
                    let sortedValues = values.sorted(by: { $0.key < $1.key })
                    cell.topLeftLabel.text = item.title
                    cell.topRightLabel.text = sortedValues.first { $0.key == Int(long) }?.value
                    cell.bottomLeftLabel.text = sortedValues.first?.value
                    cell.bottomRightLabel.text = sortedValues.last?.value
                    cell.sliderView.setNumberOfMarks(sortedValues.count)
                    cell.sliderView.selectedMark = sortedValues.firstIndex(where: { $0.key == long }) ?? 0
                    cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
                    cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside , .touchUpOutside])
                    cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside , .touchUpOutside])
                }
            }
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.cellType != OASegmentSliderTableViewCell.getIdentifier() {
            let val = stringValue(from: item.obj(forKey: "value"))
            if let pref {
                pref.setValueFrom(val, appMode: appMode)
            } else {
                widgetConfigurationSelectedValue = val
            }
            delegate?.onWidgetStateChanged()
            dismiss()
        }
    }

    //MARK: - Additions

    private func stringValue(from value: Any?) -> String {
        if let stringValue = value as? String {
            // If the value is already a String, return it
            return stringValue
        } else if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        } else {
            // Convert the value to a String using its description
            return String(describing: value)
        }
    }

    //MARK: - Selectors

    @objc private func sliderChanged(sender: UISlider) {
        let indexPath: IndexPath = IndexPath.init(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        if let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell {
            let item = tableData.item(for: indexPath)
            let values = item.obj(forKey: "values")
            if let values = values as? [Int: String] {
                let sortedValues = values.sorted(by: { $0.key < $1.key })
                let val = stringValue(from: sortedValues[cell.sliderView.selectedMark].key)
                if let pref {
                    pref.setValueFrom(val, appMode: appMode)
                } else {
                    widgetConfigurationSelectedValue = val
                    onWidgetConfigurationParamsAction?(val)
                }
               
                delegate?.onWidgetStateChanged()
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
}
