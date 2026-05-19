//
//  AlertPresenter+Actions.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 13.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

// MARK: - Routing
extension AlertPresenter {
    static func showRequestPrivateAccessAlert(handler: @escaping () -> Void) {
        let noAction = AlertActionConfig(title: localizedString("shared_string_cancel"),
                                         style: .cancel,
                                         handler: nil)
        
        let yesAction = AlertActionConfig(title: localizedString("shared_string_allow"),
                                          style: .default,
                                          handler: handler)
        let title = localizedString(UIApplication.shared.isCarPlayAppActive
                                    ? "private_access_routing_req_short"
                                    : "private_access_routing_req")
        show(title: title,
             actions: [noAction, yesAction],
             config: .carPlayOrApp)
    }
    
   static func showMissingMapsAlert(onDownloadMapsHandler: @escaping () -> Void,
                                    onViewOnPhoneHandler: @escaping () -> Void) {
        let downloadAction = AlertActionConfig(title: localizedString("missing_maps_ignore"),
                                               style: .default,
                                               handler: onDownloadMapsHandler)
       var actions = [downloadAction]

       if UIApplication.shared.mainScene != nil {
           let viewOnPhoneAction = AlertActionConfig(title: localizedString("view_on_phone"),
                                                     style: .default,
                                                     handler: onViewOnPhoneHandler)
           actions.append(viewOnPhoneAction)
       }

       let title = localizedString("missing_maps_header")
       let message = localizedString("missing_maps_description")
              
       let text = "\(title). \(message)"
        
       show(title: text,
            actions: actions,
            config: .carPlayOnly)
    }
    
    static func showRouteCalculationErrorAlert(_ error: String?, from: UIViewController) {
        guard let error, !error.isEmpty else {
            return
        }
        let isCarPlayAppActive = UIApplication.shared.isCarPlayConnected && UIApplication.shared.isCarPlayAppActive
        AlertPresenter.show(title: isCarPlayAppActive ? error : "",
                            message: error,
                            actions: [],
                            config: .carPlayOrApp,
                            fromViewController: from
        )
    }
}
