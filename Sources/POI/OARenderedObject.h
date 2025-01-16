//
//  OARenderedObject.h
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"

#include <OsmAndCore.h>
#include <OsmAndCore/PointsAndAreas.h>

@interface OARenderedObject : OAMapObject

@property (nonatomic) NSDictionary<NSString *, NSString *> *tags;

@property (nonatomic) CLLocationCoordinate2D bboxTopLeft;
@property (nonatomic) CLLocationCoordinate2D bboxBottomRight;

@property (nonatomic) NSMutableArray<NSNumber *> *x;
@property (nonatomic) NSMutableArray<NSNumber *> *y;

@property (nonatomic) NSString *iconRes;
@property (nonatomic) NSInteger order;

@property (nonatomic) BOOL visible;
@property (nonatomic) BOOL drawOnPath;

@property (nonatomic) CLLocationCoordinate2D labelLatLon;
@property (nonatomic) NSInteger labelX;
@property (nonatomic) NSInteger labelY;

@property (nonatomic) BOOL isPolygon;

- (BOOL) isText;
- (void) addLocation:(int)x y:(int)y;

- (QVector<OsmAnd::PointI>) points;

@end
