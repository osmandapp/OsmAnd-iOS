//
//  RenderedObjectViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 20/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// analog in android: RenderedObjectMenuBuilder.java

@objcMembers
final class RenderedObjectViewController: OAPOIViewController {

    private var renderedObject: OARenderedObject?
    private var detailedObject: BaseDetailsObject?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }

    init(renderedObject: OARenderedObject) {
        let poi = BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
        super.init(poi: poi)
        self.renderedObject = renderedObject // set finally
    }

    override func viewDidLoad() {
        updateMenuWithDetailedObject()
        super.viewDidLoad()
    }

    override func getTypeStr() -> String? {
        // TODO: RZR reuse detailed object and/or port fresh Java code
        guard let renderedObject else { return super.getTypeStr() }
        if renderedObject.isPolygon {
            return RenderedObjectHelper.getTranslatedType(renderedObject: renderedObject)
        }
        return super.getTypeStr()
    }
    
    override func getIcon() -> UIImage? {
        guard let renderedObject else { return super.getIcon() }
        guard detailedObject == nil else {
            return detailedObject?.syntheticAmenity.icon()
        }
        return RenderedObjectHelper.getIcon(renderedObject: renderedObject)
    }
    
    override func getOsmUrl() -> String {
        guard let renderedObject else { return super.getOsmUrl() }
        return ObfConstants.getOsmUrlForId(renderedObject)
    }
    
    private func updateMenuWithDetailedObject() {
        guard let renderedObject else { return }
        guard let details = OAAmenitySearcher.sharedInstance().searchDetailedObject(renderedObject) else { return }
        detailedObject = details
        let amenity = details.syntheticAmenity
        setup(amenity)
        updateTargetPoint(with: amenity)
        rebuildRows()
        tableView.reloadData()
    }
    
    private func updateTargetPoint(with amenity: OAPOI) {
        guard let mapPanel = OARootViewController.instance()?.mapPanel,
              let targetPoint = mapPanel.getCurrentTargetPoint() else { return }

        targetPoint.title = amenity.nameLocalized ?? amenity.name
        targetPoint.icon = amenity.type?.icon()

        mapPanel.update(targetPoint)
    }
}
