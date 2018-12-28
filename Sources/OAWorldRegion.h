//
//  OAWorldRegion.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OAWorldRegion : NSObject

// Region data:
@property (readonly) NSString* regionId;
@property (readonly) NSString* downloadsIdPrefix;
@property (readonly) NSString* nativeName;
@property (readonly) NSString* localizedName;
@property (readonly) NSString* name;
@property (readonly) NSArray* allNames;

@property (readonly) NSString* regionLeftHandDriving;
@property (readonly) NSString* regionLang;
@property (readonly) NSString* regionMetric;
@property (readonly) NSString* regionRoadSigns;
@property (readonly) NSString* wikiLink;
@property (readonly) NSString* population;

@property (readonly) CLLocationCoordinate2D bboxTopLeft;
@property (readonly) CLLocationCoordinate2D bboxBottomRight;

@property (nonatomic) NSArray *resourceTypes;

// Hierarchy:
@property (readonly, weak) OAWorldRegion* superregion;
@property (readonly) NSArray* subregions;
@property (readonly) NSArray* flattenedSubregions;

- (NSComparisonResult) compare:(OAWorldRegion*)other;

- (BOOL) purchased;
- (BOOL) isInPurchasedArea;

- (NSArray<OAWorldRegion *> *) queryAtLat:(double)lat lon:(double)lon;
- (OAWorldRegion *) findAtLat:(double)latitude lon:(double)longitude;
- (double) getArea;
- (BOOL) contain:(double) lat lon:(double) lon;
- (NSInteger) getLevel;

+ (OAWorldRegion*) loadFrom:(NSString*)ocbfFilename;

@end
