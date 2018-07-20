//
//  OAPOICategory.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAPOIBaseType.h"

@class OAPOIType;
@class OAPOIFilter;

@interface OAPOICategory : OAPOIBaseType

@property (nonatomic) NSArray<OAPOIType *> *poiTypes;
@property (nonatomic) NSArray<OAPOIFilter *> *poiFilters;
@property (nonatomic) NSString *tag;

- (void)addPoiType:(OAPOIType *)poiType;
- (void)addPoiFilter:(OAPOIFilter *)poiFilter;

- (OAPOIType *) getPoiTypeByKeyName:(NSString *)name;
- (OAPOIFilter *) getPoiFilterByName:(NSString *)name;

+ (void) addReferenceTypes:(NSArray<OAPOIType *> *)pTypes acceptedTypes:(NSMapTable<OAPOICategory *,  NSMutableSet<NSString *> *> *)acceptedTypes;

@end
