//
//  OAColorPickerViewController.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 10/09/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

// UIColorPickerViewController doesn't call colorPickerViewControllerDidFinish() at MacOS.
// Use this wrapper to handle color picker screen closing.

@objc
protocol OAColorPickerViewControllerDelegate: AnyObject {
    func onColorPickerDisappear(_ colorPicker: OAColorPickerViewController)
}

@objcMembers
final class OAColorPickerViewController: UIColorPickerViewController {
    
    weak var closingDelegete: OAColorPickerViewControllerDelegate?
    
    override func viewWillDisappear(_ animated: Bool) {
        closingDelegete?.onColorPickerDisappear(self)
        super.viewWillDisappear(animated)
    }
}
