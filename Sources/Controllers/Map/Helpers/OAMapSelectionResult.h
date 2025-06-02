//
//  OAMapSelectionResult.h
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAContextMenuProvider.h"

@interface OAMapSelectionResult : NSObject

@property CLLocation *objectLatLon;

- (instancetype) initWithPoint:(CGPoint)point;
- (CGPoint) getPoint;
- (CLLocation *) getPointLatLon;
- (NSMutableArray<OASelectedMapObject *> *) getAllObjects;
- (NSMutableArray<OASelectedMapObject *> *) getProcessedObjects;
- (void) collect:(id)object provider:(id)provider;
- (void) groupByOsmIdAndWikidataId;
- (BOOL) isEmpty;

@end
