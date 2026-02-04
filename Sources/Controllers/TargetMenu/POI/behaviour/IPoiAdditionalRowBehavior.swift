//
//  IPoiAdditionalRowBehavior.swift
//  OsmAnd
//
//  Created by Max Kojin on 01/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

protocol IPoiAdditionalRowBehavior {
    func applyCustomRules(params: PoiRowParams)
    func applyCommonRules(params: PoiRowParams)
}
