//
//  OAMapSelectionResult.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAContextMenuProvider.h"

@interface OASelectedMapObject  : NSObject

- (instancetype) initWithMapObject:(id)object provider:(id<OAContextMenuProvider>)provider;
- (id<OAContextMenuProvider>) object;
- (id<OAContextMenuProvider>) provider;

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
- (void) collect:(id)object provider:(id)provider;
- (void) groupByOsmIdAndWikidataId;
- (BOOL) isEmpty;

@end
