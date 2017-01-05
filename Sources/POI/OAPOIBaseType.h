//
//  OAPOIBaseType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAPOIType, OAPOICategory;

@interface OAPOIBaseType : NSObject<NSCopying>

@property (nonatomic, readonly) NSString *name;

@property (nonatomic) NSString *nameLocalizedEN;
@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) BOOL top;

@property (nonatomic) OAPOIBaseType *baseLangType;
@property (nonatomic) NSString *lang;
@property (nonatomic) NSArray<OAPOIType *> *poiAdditionals;
@property (nonatomic) NSArray<OAPOIType *> *poiAdditionalsCategorized;
@property (nonatomic) NSArray<NSString *> *excludedPoiAdditionalCategories;

- (instancetype)initWithName:(NSString *)name;

- (BOOL)isAdditional;
- (void)addPoiAdditional:(OAPOIType *)poiType;
- (void)addExcludedPoiAdditionalCategories:(NSArray<NSString *> *)excluded;

- (NSMutableDictionary<OAPOICategory *, NSMutableSet<NSString *> *> *) putTypes:(NSMutableDictionary<OAPOICategory *, NSMutableSet<NSString *> *> *)acceptedTypes;

+(NSMutableSet<NSString *> *)nullSet;
+(BOOL)isNullSet:(NSMutableSet<NSString *> *)set;

- (UIImage *)icon;
- (NSString *)iconName;

@end
