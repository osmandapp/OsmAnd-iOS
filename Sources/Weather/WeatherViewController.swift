//
//  WeatherViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class WeatherView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view === self {
            return nil
        }
        return view
    }
}

final class WeatherViewController: UIViewController {
    let weatherToolbar = OAWeatherToolbar()
    
//    override func loadView() {
//        self.view = WeatherView()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weatherToolbar.delegate = self
        weatherToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weatherToolbar)
       
        NSLayoutConstraint.activate([
            weatherToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weatherToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            weatherToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
//        navigationItem.leftItemsSupplementBackButton = true
//        navigationController?.navigationBar.topItem?.backButtonTitle = localizedString("shared_string_navigation")
//        navigationItem.setLeftBarButton(nil, animated: false)
        
        //self.navigationItem.backButtonTitle = localizedString("shared_string_back")
        
        // Disable large titles for navigation bar
//        self.navigationController?.navigationBar.prefersLargeTitles = false
//        
//        
//        navigationItem.setLeftBarButton(nil, animated: false)

//        // Create a back button item
//        let backButton = UIBarButtonItem(title: localizedString("shared_string_back"), style: .plain, target: self, action: #selector(onLeftNavbarButtonPressed))
//
//        // Set the back button as the left bar button item of the navigation item
//        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = backButton
//        self.navigationController?.navigationBar.topItem?.leftBarButtonItem?.animated = true
        
//        let leftMenuItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: Selector("leftMenuItemSelected:"));
//        self.navigationItem.setLeftBarButton(leftMenuItem, animated: false);
    }
}

extension WeatherViewController: OAWidgetListener {
    func widgetChanged(_ widget: OABaseWidgetView?) {
        
    }
    
    func widgetVisibilityChanged(_ widget: OABaseWidgetView, visible: Bool) {
        
    }
    
    func widgetClicked(_ widget: OABaseWidgetView) {
        
    }
}
