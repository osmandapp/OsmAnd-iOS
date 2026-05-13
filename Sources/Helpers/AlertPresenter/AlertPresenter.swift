//
//  AlertPresenter.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 13.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
enum AlertVisibility: Int {
    /// Show only in the main app.
    case appOnly
    /// Show in CarPlay if active, otherwise in the app.
    case carPlayOrApp
    /// Show only in CarPlay.
    case carPlayOnly
}

@objcMembers
final class AlertPresentationConfig: NSObject {
    let visibility: AlertVisibility

    init(visibility: AlertVisibility = .appOnly) {
        self.visibility = visibility
    }
}

extension AlertPresentationConfig {
    static let appOnly = AlertPresentationConfig()
    static let carPlayOrApp = AlertPresentationConfig(visibility: .carPlayOrApp)
    static let carPlayOnly = AlertPresentationConfig(visibility: .carPlayOnly)
}

@objcMembers
final class AlertActionConfig: NSObject {
    let title: String
    let style: UIAlertAction.Style
    let handler: (() -> Void)?
        
    var carPlayAlertStyle: CPAlertAction.Style {
        switch style {
        case .destructive: .destructive
        case .cancel: .cancel
        default: .default
        }
    }
    
    init(title: String, style: UIAlertAction.Style = .default, handler: (() -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

struct QueuedAlert: Equatable {
    let title: String
    let message: String?
    let actions: [AlertActionConfig]
    let config: AlertPresentationConfig
    let fromViewController: UIViewController?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.title == rhs.title
    }
}

/// Centralized alert presentation manager supporting:
/// - queued alert presentation
/// - duplicate filtering
/// - UIKit alerts
/// - CarPlay alerts
///
/// `AlertPresenter` guarantees that only one alert is presented at a time.
@objcMembers
final class AlertPresenter: NSObject {
    private static var alertQueue: [QueuedAlert] = []
    private static var isPresenting: Bool = false
    
    private override init() {}
    
    static func show(title: String,
                     message: String? = nil,
                     actions: [AlertActionConfig] = [],
                     config: AlertPresentationConfig = .appOnly,
                     fromViewController: UIViewController? = nil) {
        
        let newAlert = QueuedAlert(title: title,
                                   message: message,
                                   actions: actions,
                                   config: config,
                                   fromViewController: fromViewController)
        
        DispatchQueue.main.async {
            guard !alertQueue.contains(newAlert) else { return }
            
            alertQueue.append(newAlert)
            processQueue()
        }
    }
    
    private static func processQueue() {
        guard !isPresenting, let nextAlert = alertQueue.first else { return }
        
        isPresenting = true
        executePresentation(alert: nextAlert)
    }
    
    private static func completeCurrentAlert(title: String) {
        alertQueue.removeAll { $0.title == title }
        isPresenting = false
        processQueue()
    }
    
    private static func executePresentation(alert: QueuedAlert) {
        switch alert.config.visibility {
        case .appOnly:
            presentInApp(alert: alert)
        case .carPlayOrApp:
            if UIApplication.shared.isCarPlayAppActive {
                presentInCarPlay(alert: alert)
            } else {
                presentInApp(alert: alert)
            }
        case .carPlayOnly:
            if UIApplication.shared.isCarPlayAppActive {
                presentInCarPlay(alert: alert)
            } else {
                completeCurrentAlert(title: alert.title)
            }
        }
    }
    
    private static func presentInApp(alert: QueuedAlert) {
        let uiAlert = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
        
        if alert.actions.isEmpty {
            uiAlert.addAction(UIAlertAction(title: localizedString("shared_string_ok"), style: .default) { _ in
                completeCurrentAlert(title: alert.title)
            })
        } else {
            for config in alert.actions {
                uiAlert.addAction(UIAlertAction(title: config.title, style: config.style) { _ in
                    config.handler?()
                    completeCurrentAlert(title: alert.title)
                })
            }
        }
        
        let presenter = alert.fromViewController ?? OARootViewController.instance()
        presenter?.present(uiAlert, animated: true)
    }
    
    private static func presentInCarPlay(alert: QueuedAlert) {
        guard let delegate = UIApplication.shared.carPlaySceneDelegate else {
            return
        }
        
        let wrappedActions = alert.actions.map { original in
            AlertActionConfig(title: original.title, style: original.style) {
                original.handler?()
                completeCurrentAlert(title: alert.title)
            }
        }
        
        if wrappedActions.isEmpty {
            delegate.showAlertWith(title: alert.title) {
                completeCurrentAlert(title: alert.title)
            }
        } else {
            delegate.showAlert(title: alert.title, actions: wrappedActions)
        }
    }
}
