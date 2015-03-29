//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore.h>

const static int kSearchRadiusKm[] = {1, 2, 5, 10, 20, 50, 100, 200, 500};

@class OAPOI;
@class OAPOIType;

@protocol OAPOISearchDelegate

-(void)poiFound:(OAPOI *)poi;
-(void)searchDone:(BOOL)wasInterrupted;

@end

@interface OAPOIHelper : NSObject

@property (nonatomic, readonly) BOOL isSearchDone;
@property (nonatomic, assign) int searchLimit;

@property (nonatomic, readonly) NSArray *poiTypes;
@property (nonatomic, readonly) NSDictionary *poiCategories;
@property (nonatomic, readonly) NSDictionary *poiFilters;

@property (nonatomic) OsmAnd::PointI myLocation;

@property (weak, nonatomic) id<OAPOISearchDelegate> delegate;

+ (OAPOIHelper *)sharedInstance;

- (void)updatePhrases;

- (NSArray *)poiTypesForCategory:(NSString *)categoryName;
- (NSArray *)poiTypesForFilter:(NSString *)filterName;
- (NSArray *)poiFiltersForCategory:(NSString *)categoryName;

- (OAPOIType *)getPoiType:(NSString *)tag value:(NSString *)value;
- (OAPOIType *)getPoiTypeByCategory:(NSString *)category name:(NSString *)name;

-(void)setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom;

-(void)findPOIsByKeyword:(NSString *)keyword;
-(void)findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)category poiTypeName:(NSString *)type radiusIndex:(int *)radiusIndex;
-(BOOL)breakSearch;

@end
