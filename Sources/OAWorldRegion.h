//
//  OAWorldRegion.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

static NSString *kWorldBasemapRegionId = @"world_basemap";
static NSString *kWorldBasemapMiniRegionId = @"world_basemap_mini";
static NSString *kAntarcticaRegionId = @"antarctica";
static NSString *kAfricaRegionId = @"africa";
static NSString *kAsiaRegionId = @"asia";
static NSString *kAustraliaAndOceaniaRegionId = @"australia-oceania-all";
static NSString *kCentralAmericaRegionId = @"centralamerica";
static NSString *kEuropeRegionId = @"europe";
static NSString *kNorthAmericaRegionId = @"northamerica";
static NSString *kRussiaRegionId = @"russia";
static NSString *kJapanRegionId = @"japan_asia";
static NSString *kGermanyRegionId = @"europe_germany";
static NSString *kFranceRegionId = @"europe_france";
static NSString *kSouthAmericaRegionId = @"southamerica";
static NSString *kWorldRegionId = @"world";
static NSString *kUnitedKingdomRegionId = @"europe_gb";

@class OAProduct, OAPointIContainer, OAResourceGroupItem, QuadRect;

@interface OAWorldRegion : NSObject

// Region data:
@property (readonly) NSString* regionId;
@property (readonly) NSString* downloadsIdPrefix;
@property (readonly) NSString* acceptedExtension;
@property (readonly) NSString* nativeName;
@property (readonly) NSString* localizedName;
@property (readonly) NSString* name;
@property (readonly) NSArray* allNames;

@property (readonly) NSString* regionParentFullName;
@property (readonly) NSString* regionName;
@property (readonly) NSString* regionNameEn;

@property (readonly) NSString* regionLeftHandDriving;
@property (readonly) NSString* regionLang;
@property (readonly) NSString* regionMetric;
@property (readonly) NSString* regionRoadSigns;
@property (readonly) NSString* wikiLink;
@property (readonly) NSString* population;
@property (readonly) BOOL regionMap;
@property (readonly) BOOL regionRoads;
@property (readonly) BOOL regionJoinMap;
@property (readonly) BOOL regionJoinRoads;

@property (readonly) CLLocationCoordinate2D bboxTopLeft;
@property (readonly) CLLocationCoordinate2D bboxBottomRight;
@property (readonly) CLLocationCoordinate2D regionCenter;
@property (nonatomic) QuadRect *boundingBox;

@property (nonatomic) NSArray *resourceTypes;
@property (nonatomic) OAResourceGroupItem *groupItem;

// Hierarchy:
@property (readonly, weak) OAWorldRegion* superregion;
@property (readonly) NSArray<OAWorldRegion *> *subregions;
@property (readonly) NSArray<OAWorldRegion *> *flattenedSubregions;

@property (readonly) NSMutableDictionary<NSString *, OAWorldRegion *> *fullNamesToRegionData;
@property (readonly) NSMutableDictionary<NSString *, NSString *> *downloadNamesToFullNames;

- (instancetype) initWithId:(NSString*)regionId andLocalizedName:(NSString*)localizedName;

- (NSComparisonResult) compare:(OAWorldRegion *)other;

- (BOOL) purchased;
- (BOOL) isInPurchasedArea;

- (NSArray<OAWorldRegion *> *) queryAtLat:(double)lat lon:(double)lon;
- (NSArray<OAWorldRegion *> *) getWorldRegionsAt:(double)latitude longitude:(double)longitude;
- (NSArray<OAWorldRegion *> *)getWorldRegionsAtWithoutSort:(double)latitude longitude:(double)longitude;
- (OAWorldRegion *) findAtLat:(double)latitude lon:(double)longitude;
- (NSString *) getCountryNameAtLat:(double)latitude lon:(double)longitude;
- (double) getArea;
- (BOOL) contain:(double) lat lon:(double) lon;
- (NSArray<OAPointIContainer *> *) getAllPolygons;

- (NSInteger) getLevel;
- (BOOL) containsSubregion:(NSString *)regionId;
- (OAWorldRegion *) getSubregion:(NSString *)regionId;
- (OAWorldRegion *) getFlattenedSubregion:(NSString *)regionId;
- (NSArray<OAWorldRegion *> *) getFlattenedSubregions:(NSArray<NSString *> *)regionIds;
- (NSMutableArray<OAWorldRegion *> *) getSuperRegions;
- (OAWorldRegion *) getPrimarySuperregion;
- (OAWorldRegion *) getRegionDataByDownloadName:(NSString *)downloadName;
- (OAProduct *) getProduct;

- (void) addSubregion:(OAWorldRegion *)subregion;

+ (OAWorldRegion *) loadFrom:(NSString *)ocbfFilename;

- (void)buildResourceGroupItem;
- (void)updateGroupItems:(OAWorldRegion *)subregion type:(NSNumber *)type;
- (BOOL)hasGroupItems;
+ (NSArray<OAWorldRegion *> *)removeDuplicates:(NSArray<OAWorldRegion *> *)regions;
- (BOOL)containsRegion:(OAWorldRegion *)another;

- (BOOL)isContinent;
- (BOOL)containsPoint:(CLLocation *)location;

- (NSString *) getLocaleName:(NSString *)downloadName includingParent:(BOOL)includingParent;
- (NSString *) getLocaleName:(NSString *)downloadName includingParent:(BOOL)includingParent reversed:(BOOL)reversed;
- (NSString *) getLocaleName:(NSString *)downloadName divider:(NSString *)divider includingParent:(BOOL)includingParent reversed:(BOOL)reversed;
- (NSString *) getLocaleNameByFullName:(NSString *)fullName divider:(NSString *)divider includingParent:(BOOL)includingParent reversed:(BOOL)reversed;
- (NSString *) getLocaleNameWithParent:(NSMutableArray<OAWorldRegion *> *)superRegions regionName:(NSString *)regionName divider:(NSString *)divider reversed:(BOOL)reversed;

@end
