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

final class AppearanceData: NSObject {
    private var map: [GpxParameter: (Bool, Any?)] = [:]
    weak var delegate: AppearanceChangedDelegate?
    
    override init() {
        super.init()
    }
    
    init(data: AppearanceData) {
        self.map = data.map
        super.init()
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return map.count == other.map.count && map.allSatisfy { (key, value) in
            guard let otherValue = other.map[key] else { return false }
            return compareTuples(value, otherValue)
        }
    }
    
    private func notifyAppearanceModified() {
        delegate?.onAppearanceChanged()
    }
    
    private func isValidValue(parameter: GpxParameter, value: Any?) -> Bool {
        guard parameter.isAppearanceParameter() else { return false }
        return true
    }
    
    func getParameter<T>(for parameter: GpxParameter) -> T? {
        guard let tuple = map[parameter] else { return nil }
        return tuple.1 as? T
    }
    
    func setParameter(_ parameter: GpxParameter, value: Any?) {
        guard isValidValue(parameter: parameter, value: value) else { return }
        map[parameter] = (false, value)
        notifyAppearanceModified()
    }
    
    func resetParameter(_ parameter: GpxParameter) {
        guard parameter.isAppearanceParameter() else { return }
        map[parameter] = (true, nil)
        notifyAppearanceModified()
    }
    
    func shouldResetParameter(_ parameter: GpxParameter) -> Bool {
        guard parameter.isAppearanceParameter() else { return false }
        return map[parameter]?.0 ?? false
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

extension AppearanceData {
    private func compareTuples(_ lhs: (Bool, Any?), _ rhs: (Bool, Any?)) -> Bool {
        guard lhs.0 == rhs.0 else { return false }
        switch (lhs.1, rhs.1) {
        case (nil, nil):
            return true
        case (nil, _), (_, nil):
            return false
        case let (lValue?, rValue?):
            guard let lObj = lValue as? NSObject, let rObj = rValue as? NSObject else { return false }
            return lObj.isEqual(rObj)
        }
    }
}
