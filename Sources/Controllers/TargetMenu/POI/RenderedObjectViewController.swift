//
//  RenderedObjectViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 20/01/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class RenderedObjectViewController: OAPOIViewController {
    
    private var renderedObject: OARenderedObject!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }
    
    init(renderedObject: OARenderedObject) {
        let poi = RenderedObjectHelper.getSyntheticAmenity(renderedObject: renderedObject)
        poi.obfId >>= 1;
        
        super.init(poi: poi)
        self.renderedObject = renderedObject
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIAfterAmenitySearch()
    }
    
    private func updateUIAfterAmenitySearch() {
        Task {
            do {
                if let foundAmenity = try await searchAmenity() {
                    await MainActor.run {
                        setup(foundAmenity)
                        rebuildRows()
                        tableView.reloadData()
                    }
                }
            } catch {
                print("Poi finding error: \(error)")
            }
        }
    }
    
    private func searchAmenity() async throws -> OAPOI? {
        OAPOIHelper.findPOI(byOsmId: ObfConstants.getOsmObjectId(renderedObject), lat: poi.latitude, lon: poi.longitude)
    }
    
    override func getTypeStr() -> String? {
        if renderedObject.isPolygon {
            return RenderedObjectHelper.getTranslatedType(renderedObject: renderedObject)
        }
        return super.getTypeStr()
    }
    
    override func getIcon() -> UIImage? {
        return RenderedObjectHelper.getIcon(renderedObject: renderedObject)
    }
    
    override func getOsmUrl() -> String! {
        ObfConstants.getOsmUrlForId(renderedObject)
    }
}
