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
    
    private var cachedNameStr: String?
    private var cachedTypeStr: String?
    
    private var provider: RenderedObjectAmenityProvider!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(renderedObject: OARenderedObject) {
        let poi = BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
        super.init(poi: poi)
        self.renderedObject = renderedObject
        provider = RenderedObjectAmenityProvider(renderedObject: renderedObject)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }
    
    override func viewDidLoad() {
        updateMenuWithDetailedObject()
        super.viewDidLoad()
    }
    
    override func getNameStr() -> String? {
        let name =  provider.nameOnlyString()
        
        if !name.isEmpty {
            return name
        }
        
        return getTypeStr()
    }
    
    override func getTypeStr() -> String? {
        let typeString = provider.typeString() { super.getTypeStr() }
        return typeString ?? super.getTypeStr()
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
        provider.detailsObject = detailedObject
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
