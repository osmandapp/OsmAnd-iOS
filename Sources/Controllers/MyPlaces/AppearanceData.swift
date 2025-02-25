//
//  AppearanceData.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 19.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

protocol AppearanceChangedDelegate: AnyObject {
    func onAppearanceChanged()
}

struct AppearancePair {
    let shouldReset: Bool
    let value: Any?
}

final class AppearanceData: NSObject {
    private var map: [GpxParameter: AppearancePair] = [:]
    weak var delegate: AppearanceChangedDelegate?
    
    override init() {
        super.init()
    }
    
    init(data: AppearanceData) {
        self.map = data.map
        super.init()
    }
    
    private func notifyAppearanceModified() {
        delegate?.onAppearanceChanged()
    }
    
    private func isValidValue(parameter: GpxParameter, value: Any?) -> Bool {
        guard parameter.isAppearanceParameter() else { return false }
        return true
    }
    
    func getParameter<T>(for parameter: GpxParameter) -> T? {
        guard let pair = map[parameter] else { return nil }
        return pair.value as? T
    }
    
    func setParameter(_ parameter: GpxParameter, value: Any?) {
        if isValidValue(parameter: parameter, value: value) {
            map[parameter] = AppearancePair(shouldReset: false, value: value)
            notifyAppearanceModified()
        }
    }
    
    func resetParameter(_ parameter: GpxParameter) {
        guard parameter.isAppearanceParameter() else { return }
        map[parameter] = AppearancePair(shouldReset: true, value: nil)
        notifyAppearanceModified()
    }
    
    func shouldResetParameter(_ parameter: GpxParameter) -> Bool {
        guard parameter.isAppearanceParameter() else { return false }
        return map[parameter]?.shouldReset ?? false
    }
    
    func shouldResetAnything() -> Bool {
        let params = GpxParameter.values()
        for i in 0..<params.size {
            if let param = params.get(index: i), shouldResetParameter(param) {
                return true
            }
        }
        
        return false
    }
}
