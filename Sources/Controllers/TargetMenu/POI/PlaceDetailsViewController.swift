//
//  PlaceDetailsViewController.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/09/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class PlaceDetailsViewController: OAPOIViewController {
    
    private var detailsObject: BaseDetailsObject?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: "OAPOIViewController", bundle: nibBundleOrNil)
    }
    
    init(poi: OAPOI, detailsObject: BaseDetailsObject) {
        super.init(poi: poi)
        self.detailsObject = detailsObject
        setObject(detailsObject)
    }
    
    override func setObject(_ object: Any!) {
        if let detailsObj = object as? BaseDetailsObject {
            poi = detailsObj.syntheticAmenity
        } else {
            super.setObject(object)
        }
    }
    
//    override func buildTopRows(_ rows: NSMutableArray!) {
//        super.buildTopRows(rows)
//    }
    
    // override if needed
    //- (void) buildRowsInternal:(NSMutableArray<OARowInfo *> *)rows
    //- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows
    //- (void) buildWithinRow
    //- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
    //- (void) buildRowsPoi:(BOOL)isWiki
    //- (void) buildCoordinateRows:(NSMutableArray<OARowInfo *> *)rows
    //- (void) addNearbyImagesIfNeeded
    //- (void) addMapillaryCardsRowInfoIfNeeded
}
