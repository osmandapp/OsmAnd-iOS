//
//  AisMessageDecoder.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import OsmAndShared

final class AisMessageDecoder {
    private let dataListener = AisSharedDataListener()
    private lazy var listener = OsmAndShared.AisMessageListener(dataListener: dataListener)

    func decode(sentence: String) -> AisObject? {
        dataListener.lastObject = nil
        listener.processLine(line: sentence)
        return dataListener.lastObject
    }
}

private final class AisSharedDataListener: NSObject, OsmAndShared.AisDataListener {
    var lastObject: AisObject?

    func onAisObjectReceived(ais: AisObject) {
        lastObject = ais
    }
}
