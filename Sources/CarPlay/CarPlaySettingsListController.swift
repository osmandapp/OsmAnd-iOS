//
//  CarPlaySettingsListController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 23.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CarPlay

@objcMembers
final class CarPlaySettingsListController: OABaseCarPlayInterfaceController {
    private var listTemplate: CPListTemplate?
    private var mapModeController: CarPlayMapModeListController?
    private var mapOrientationController: CarPlayMapOrientationListController?
    private var applicationModeChangedObserver: OAAutoObserverProxy?

    override init(interfaceController: CPInterfaceController) {
        super.init(interfaceController: interfaceController)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onProfileSettingSet(notification:)),
                                               name: NSNotification.Name(kNotificationSetProfileSetting),
                                               object: nil)
        applicationModeChangedObserver = OAAutoObserverProxy(self,
                                                             withHandler: #selector(onApplicationModeChanged),
                                                             andObserve: OsmAndApp.swiftInstance().applicationModeChangedObservable)
    }

    override func present() {
        let template = CPListTemplate(title: localizedString("shared_string_settings"), sections: [makeSection()])
        listTemplate = template
        safePush(template, animated: true)
    }

    private func makeSection() -> CPListSection {
        CPListSection(items: [makeMapModeItem(), makeMapOrientationItem()])
    }

    private func makeMapModeItem() -> CPListItem {
        if mapModeController == nil {
            mapModeController = CarPlayMapModeListController(
                interfaceController: interfaceController
            ) { [weak self] in
                self?.reloadSections()
            }
        }
        let mapMode = CPListItem(text: localizedString("map_mode"), detailText: mapModeController?.currentTitle())
        mapMode.accessoryType = .disclosureIndicator
        mapMode.handler = { [weak self] _, completion in
            guard let self else {
                completion()
                return
            }
            self.mapModeController?.present()
            completion()
        }
        return mapMode
    }

    private func makeMapOrientationItem() -> CPListItem {
        if mapOrientationController == nil {
            mapOrientationController = CarPlayMapOrientationListController(interfaceController: interfaceController)
        }
        let mapOrientation = CPListItem(text: localizedString("rotate_map_to"), detailText: mapOrientationController?.currentTitle())
        mapOrientation.accessoryType = .disclosureIndicator
        mapOrientation.handler = { [weak self] _, completion in
            guard let self else {
                completion()
                return
            }
            self.mapOrientationController?.present()
            completion()
        }
        return mapOrientation
    }

    private func reloadSections() {
        listTemplate?.updateSections([makeSection()])
    }

    private func reloadMapOrientation() {
        reloadSections()
        mapOrientationController?.reloadSections()
    }

    @objc private func onProfileSettingSet(notification: Notification) {
        guard let preferenceKeys = notification.userInfo?[kPreferenceKeysUserInfoKey] as? Set<String>,
              preferenceKeys.contains(OAAppSettings.sharedManager().rotateMap.key) else {
            return
        }
        reloadMapOrientation()
    }

    @objc private func onApplicationModeChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.reloadMapOrientation()
        }
    }
    
    deinit {
        applicationModeChangedObserver?.detach()
        NotificationCenter.default.removeObserver(self)
    }
}
