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

extension UIBarButtonItem {
    static func createButton(image: UIImage?,
                             title: String?,
                             target: Any,
                             action: Selector) -> UIBarButtonItem {
        let button = UIButton()
        if let image {
            button.setImage(image, for: .normal)
        }
        if let title {
            button.setTitle(title, for: .normal)
        }
        button.addTarget(target, action: action, for: .touchUpInside)
        button.sizeToFit()
        return UIBarButtonItem(customView: button)
    }
}

@objcMembers
final class WeatherViewController: UIViewController {
    let weatherToolbar = OAWeatherToolbar()
    
    var onCloseButtonAction: (() -> Void)?
    
    override func loadView() {
        let weatherView = WeatherView()
        self.view = weatherView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weatherToolbar.delegate = self
        weatherToolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(weatherToolbar)
        
        title = localizedString("shared_string_weather")
        
        let backButton = UIBarButtonItem(image: UIImage(named: "ic_navbar_chevron"), style: .plain, target: self, action: #selector(onCloseButtonTapped))
        backButton.title = localizedString("shared_string_back")
        
//        let backButton = UIBarButtonItem(title: localizedString("shared_string_back"), style: .plain, target: self, action: #selector(onCloseButtonTapped))
        navigationController?.navigationBar.topItem?.setLeftBarButton(backButton, animated: false)
        
        let settingsButton = UIBarButtonItem(image: UIImage(named: "ic_navbar_settings")?.withTintColor(.iconColorActive, renderingMode: .alwaysTemplate), style: .plain, target: self, action: #selector(onSettingsButtonTapped))
        navigationController?.navigationBar.topItem?.setRightBarButton(settingsButton, animated: false)
       
        NSLayoutConstraint.activate([
            weatherToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            weatherToolbar.topAnchor.constraint(equalTo: view.topAnchor),
            weatherToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarAppearance()
    }
    
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.titleTextAttributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline), NSAttributedString.Key.foregroundColor: UIColor.textColorPrimary]
        
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor.textColorActive
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    @objc private func onSettingsButtonTapped() {
        let weatherLayerSettingsViewController = WeatherDataSourceViewController()
        let navigationController = UINavigationController(rootViewController: weatherLayerSettingsViewController)
        navigationController.modalPresentationStyle = .pageSheet

        if let sheet = navigationController.presentationController as? UISheetPresentationController {
            sheet.detents = [.medium()]
            sheet.preferredCornerRadius = 20
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        
        OARootViewController.instance()?.present(navigationController, animated: true)
    }
    
    @objc private func onCloseButtonTapped() {
        onCloseButtonAction?()
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
