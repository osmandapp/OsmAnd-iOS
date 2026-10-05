//
//  WikiNetworkResponseListener.swift
//  OsmAnd Maps
//
//  Bridges WikiCoreHelper raw responses to a closure.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

final class WikiNetworkResponseListener: NSObject, WikiCoreHelperNetworkResponseListener {
    private let onRawResponse: (String) -> Void

    init(onRawResponse: @escaping (String) -> Void) {
        self.onRawResponse = onRawResponse
    }

    func onGetRawResponse(response: String) {
        onRawResponse(response)
    }
}
