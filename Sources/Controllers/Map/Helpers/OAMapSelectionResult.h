//
//  OAMapSelectionResult.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@interface OASelectedMapObject  : NSObject

//- (instancetype) initWithMapObject:(id)object provider:(id)provider;
- (instancetype) initWithMapObject:(id)object;
- (id) object;
//- (id) provider;

@end

@interface OASelectedGpxPoint: NSObject
{
    
}
@end

@interface OAMapSelectionResult : NSObject

@property CLLocationCoordinate2D objectLatLon;

- (instancetype) initWithPoint:(CGPoint)point;
- (CGPoint) getPoint;
- (CLLocationCoordinate2D) getPointLatLon;
- (NSMutableArray<OASelectedMapObject *> *) getAllObjects;
- (NSMutableArray<OASelectedMapObject *> *) getProcessedObjects;
- (void) collect:(id)object;
- (void) groupByOsmIdAndWikidataId;
- (BOOL) isEmpty;

@end
