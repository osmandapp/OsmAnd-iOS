//
//  RenderedObjectViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 20/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class RenderedObjectViewController: OAPOIViewController {

    private var renderedObject: OARenderedObject?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }

    init(renderedObject: OARenderedObject) {
        let poi = RenderedObjectHelper.getSyntheticAmenity(renderedObject: renderedObject)
        super.init(poi: poi)
        self.renderedObject = renderedObject // set finally
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateMenuWithDetailedObject()
    }

    private func updateMenuWithDetailedObject() {
        guard let ro = renderedObject else { return }
        guard let details = OAAmenitySearcher.sharedInstance().searchDetailedObject(ro) else { return }
        setup(details.syntheticAmenity)
        rebuildRows()
        tableView.reloadData()
    }

    override func getTypeStr() -> String? {
        // TODO RZR reuse detailed object and/or port fresh Java code
        guard let ro = renderedObject else { return super.getTypeStr() }
        if ro.isPolygon {
            return RenderedObjectHelper.getTranslatedType(renderedObject: ro)
        }
        return super.getTypeStr()
    }
    
    override func getIcon() -> UIImage? {
        guard let ro = renderedObject else { return super.getIcon() }
        return RenderedObjectHelper.getIcon(renderedObject: ro)
    }
    
    override func getOsmUrl() -> String {
        guard let ro = renderedObject else { return super.getOsmUrl() }
        return ObfConstants.getOsmUrlForId(ro)
    }
}
