//
//  WikipediaRowBehavior.swift
//  OsmAnd
//
//  Created by Max Kojin on 04/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class WikipediaRowBehavior: DefaultPoiAdditionalRowBehaviour {
   
    override func applyCustomRules(params: PoiRowParams) {
        super.applyCustomRules(params: params)
        
        let wikiParams = WikiAlgorithms.getWikiParams(key: params.key, value: params.value)
        params.builder.text = wikiParams.0
        params.builder.hiddenUrl = wikiParams.1
    }
}
