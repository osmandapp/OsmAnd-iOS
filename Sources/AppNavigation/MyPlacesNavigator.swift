//
//  MyPlacesNavigator.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 17.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class MyPlacesNavigator: NSObject {
    private weak var root: OARootViewController?

    init(rootViewController: OARootViewController) {
        self.root = rootViewController
        super.init()
    }

    func openFavorites() {
        openMyPlaces(tab: .favorites)
    }

    func openTracks() {
        openMyPlaces(tab: .tracks)
    }

    func openTrack(_ track: TrackItem) {
        guard let root,
              let nav = root.navigationController else { return }

        let history = nav.saveCurrentStateForScrollableHud()

        root.mapPanel.openTargetViewWithGPX(
            fromTracksList: track,
            navControllerHistory: history,
            fromTrackMenu: false,
            selectedTab: .overviewTab
        )
    }
    
    func openTrack(gpxFilePath: String) {
        guard let item = OAGPXDatabase.sharedDb().getGPXItem(gpxFilePath) else { return }
        let track = TrackItem(file: item.file)
        openTrack(track)
    }

    private func openMyPlaces(tab: MyPlacesContainerViewController.Tab) {
        guard let root,
              let nav = root.navigationController else { return }

        if let myPlaces = nav.visibleViewController as? MyPlacesContainerViewController {
            if myPlaces.availableTabs.contains(tab) {
                myPlaces.selectedTab = tab
                myPlaces.switchToWithSegmentControl(tab: tab)
            }
            return
        }

        nav.dismiss(animated: false)
        nav.popToRootViewController(animated: false)

        let myPlaces = MyPlacesContainerViewController()
        myPlaces.loadViewIfNeeded()
        myPlaces.selectedTab = tab
        nav.pushViewController(myPlaces, animated: true)
    }
}
