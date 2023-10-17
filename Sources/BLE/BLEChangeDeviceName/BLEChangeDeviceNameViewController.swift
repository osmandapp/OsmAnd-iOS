//
//  BLEChangeDeviceNameViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 17.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension BLEChangeDeviceNameViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        updateFileNameFromEditText(name: textView.text)
//        generateData()
//        tableView.reloadData()
//        [textView sizeToFit];
//        [self.tableView beginUpdates];
//        UITableViewHeaderFooterView *footer = [self.tableView footerViewForSection:0];
//        footer.textLabel.textColor = _inputFieldError != nil ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_text_footer);
//        footer.textLabel.text = _inputFieldError;
//        [footer sizeToFit];
//        [self.tableView endUpdates];
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false;
        }
        return true;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func updateFileNameFromEditText(name: String) {
        let text = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            
        } else if isIncorrectFileName(text) {
            
        } else {
            newDeviceName = text
        }
    }
    
    func isIncorrectFileName(_ fileName: String) -> Bool {
        let isFileNameEmpty = fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        let illegalFileNameCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:;.,")
        let hasIncorrectSymbols = fileName.rangeOfCharacter(from: illegalFileNameCharacters) != nil
        
        return isFileNameEmpty || hasIncorrectSymbols
    }
    
//    - (void) updateFileNameFromEditText:(NSString *)name
//    {
//        _doneButtonEnabled = NO;
//        NSString *text = name.trim;
//        if (text.length == 0)
//        {
//            _inputFieldError = OALocalizedString(@"empty_filename");
//        }
//        else if ([self isIncorrectFileName:name])
//        {
//            _inputFieldError = OALocalizedString(@"incorrect_symbols");
//        }
//        else if ([self isFolderExist:name])
//        {
//            _inputFieldError = OALocalizedString(@"folder_already_exsists");
//        }
//        else
//        {
//            _inputFieldError = nil;
//            _newFolderName = text;
//            _doneButtonEnabled = YES;
//        }
//        self.doneButton.enabled = _doneButtonEnabled;
//    }
}

final class BLEChangeDeviceNameViewController: OABaseNavbarViewController {
    
    var device: Device!
    var onSaveAction: (() -> Void)? = nil
    
    private var isFirstLaunch = true
    
    private var newDeviceName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newDeviceName = device.deviceName
    }
    
    override func getTitle() -> String! {
        "Name"
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let save = UIBarButtonItem(barButtonSystemItem: .save,
                                  target: self,
                                  action: #selector(onRightNavbarButtonPressed))
        save.tintColor = UIColor.buttonBgColorPrimary
        return [save]
    }
    
    override func getLeftNavbarButton() -> UIBarButtonItem! {
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel,
                                  target: self,
                                  action: #selector(onRightNavbarButtonPressed))
        cancel.tintColor = UIColor.buttonBgColorPrimary
        return cancel
    }
    
    override func onRightNavbarButtonPressed() {
        #warning("add save")
        onSaveAction?()
    }
    
    override func onLeftNavbarButtonPressed() {
        dismiss()
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        if item.cellType == OATextMultilineTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OATextMultilineTableViewCell.getIdentifier()) as? OATextMultilineTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OATextMultilineTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OATextMultilineTableViewCell
                cell?.leftIconVisibility(false)
                cell?.textView.isUserInteractionEnabled = true
                cell?.textView.isEditable = true
                cell?.textView.delegate = self
                cell?.textView.returnKeyType = .done
                cell?.textView.enablesReturnKeyAutomatically = true
            }
            if let cell {
                if isFirstLaunch {
                    cell.textView.becomeFirstResponder()
                    isFirstLaunch = false;
                }
                cell.textView.text = item.title
                cell.textView.tag = indexPath.section << 10 | indexPath.row;
                cell.clearButton.tag = cell.textView.tag;
                cell.clearButton.removeTarget(nil, action: nil, for: .touchUpInside)
                cell.clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
            }
            outCell = cell
        }
        return outCell
    }
    
    @objc private func onClearButtonPressed() {
        newDeviceName = ""
        generateData()
        tableView.reloadData()
    }
    
    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let name = section.createNewRow()
        
        name.cellType = OATextMultilineTableViewCell.getIdentifier()
        name.key = "name_key"
        name.title = newDeviceName
    }
}
