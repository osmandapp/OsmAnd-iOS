//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Data/Amenity.h>

#define kSearchLimit 200
const static int kSearchRadiusKm[] = {1, 2, 5, 10, 20, 50, 100};

@class OAPOI;
@class OAPOIType;
@class OAPOIBaseType;

@protocol OAPOISearchDelegate

-(void)poiFound:(OAPOI *)poi;
-(void)searchDone:(BOOL)wasInterrupted;

@end

@interface OAPOIHelper : NSObject

@property (nonatomic, readonly) BOOL isSearchDone;
@property (nonatomic, assign) int searchLimit;

@property (nonatomic, readonly) NSArray *poiTypes;
@property (nonatomic, readonly) NSArray *poiCategories;
@property (nonatomic, readonly) NSArray *poiFilters;

@property (nonatomic) OsmAnd::PointI myLocation;

@property (weak, nonatomic) id<OAPOISearchDelegate> delegate;
@property (weak, nonatomic) id<OAPOISearchDelegate> tempDelegate;

+ (OAPOIHelper *)sharedInstance;

- (void)updatePhrases;

- (NSArray *)poiFiltersForCategory:(NSString *)categoryName;

- (OAPOIType *)getPoiType:(NSString *)tag value:(NSString *)value;
- (OAPOIType *)getPoiTypeByCategory:(NSString *)category name:(NSString *)name;
- (OAPOIBaseType *) getAnyPoiAdditionalTypeByKey:(NSString *)name;

-(NSString *)getPhraseByName:(NSString *)name;
-(NSString *)getPhraseENByName:(NSString *)name;

-(void)setVisibleScreenDimensions:(OsmAnd::AreaI)area zoomLevel:(OsmAnd::ZoomLevel)zoom;

-(void)findPOIsByKeyword:(NSString *)keyword;
-(void)findPOIsByKeyword:(NSString *)keyword categoryName:(NSString *)category poiTypeName:(NSString *)type radiusIndex:(int *)radiusIndex;

+(NSArray<OAPOI *> *)findPOIsByTagName:(NSString *)tagName name:(NSString *)name location:(OsmAnd::PointI)location categoryName:(NSString *)categoryName poiTypeName:(NSString *)typeName radius:(int)radius;

-(BOOL)breakSearch;

+ (void)processLocalizedNames:(QHash<QString, QString>)localizedNames nativeName:(NSString *)nativeName nameLocalized:(NSMutableString *)nameLocalized names:(NSMutableDictionary *)names;
+ (void)processDecodedValues:(QList<OsmAnd::Amenity::DecodedValue>)decodedValues content:(NSMutableDictionary *)content values:(NSMutableDictionary *)values;

@end
