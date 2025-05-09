//
//  OARenderedObject.h
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"
#import "OrderedDictionary.h"

@interface OARenderedObject : OAMapObject

@property (nonatomic) MutableOrderedDictionary<NSString *, NSString *> *tags;

@property (nonatomic) NSInteger bboxLeft;
@property (nonatomic) NSInteger bboxTop;
@property (nonatomic) NSInteger bboxRight;
@property (nonatomic) NSInteger bboxBottom;

@property (nonatomic) NSString *iconRes;
@property (nonatomic) NSInteger order;

@property (nonatomic) BOOL visible;
@property (nonatomic) BOOL drawOnPath;

@property (nonatomic) CLLocationCoordinate2D labelLatLon;
@property (nonatomic) NSInteger labelX;
@property (nonatomic) NSInteger labelY;

@property (nonatomic) BOOL isPolygon;

- (void) setBBox:(int)left top:(int)top right:(int)right bottom:(int)bottom;
- (BOOL) isText;
- (long) estimatedArea;

@end
