//
//  CurrentTimeWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objcMembers
final class CurrentTimeWidget: OASimpleWidget {
    
    let calendar = Calendar.current
    var cachedDate: Date?

    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: .currentTime)
        setIconFor(.currentTime)
        setText(nil, subtext: nil)
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        let currentDate = Date()
        if let cachedDate {
            let cachedDateComponents = calendar.dateComponents([.hour, .minute], from: cachedDate)
            let currentComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
            
            guard let previousHour = cachedDateComponents.hour,
               let currentHour = currentComponents.hour,
               let previousMinute = cachedDateComponents.minute,
               let currentMinute = currentComponents.minute else { 
                return false
            }
            
            if isUpdateNeeded() || (currentHour > previousHour || (currentHour == previousHour && currentMinute > previousMinute)) {
                updateFormatedText(currentDate: currentDate, hour: currentHour, minute: currentMinute)
                return true
            }
        } else {
            let dateComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
            guard let hour = dateComponents.hour,
                  let minute = dateComponents.minute else { return false }
            updateFormatedText(currentDate: currentDate, hour: hour, minute: minute)
            return true
        }
        return false
    }
    
    private func updateFormatedText(currentDate: Date, hour: Int, minute: Int) {
        cachedDate = currentDate
        let formattedTime = String(format: "%02d:%02d", hour, minute)
        setText(formattedTime, subtext: nil)
    }
}
