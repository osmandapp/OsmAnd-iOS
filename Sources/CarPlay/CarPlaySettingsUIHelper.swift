//
//  CarPlaySettingsUIHelper.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 30.09.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class CarPlaySettingsUIHelper {
    static func checkmarkImage(isSelected: Bool) -> UIImage? {
        guard isSelected else { return nil }
        if #available(iOS 26.0, *) {
            return .icCheckmarkDefault
        }
        return .icCheckmarkDefault.resizedTemplateImage(with: 20)
    }
}
