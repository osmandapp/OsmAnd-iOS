//
//  OAPOIBaseType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAPOIType, OAPOICategory;

@interface OAPOIBaseType : NSObject

@property (nonatomic, readonly) NSString *name;

@property (nonatomic) NSString *nameLocalizedEN;
@property (nonatomic) NSString *nameLocalized;
@property (nonatomic) NSString *nameSynonyms;

@property (nonatomic) BOOL top;

@property (nonatomic) BOOL nonEditableOsm;

@property (nonatomic) OAPOIBaseType *baseLangType;
@property (nonatomic) NSString *lang;
@property (nonatomic) NSArray<OAPOIType *> *poiAdditionals;
@property (nonatomic) NSArray<OAPOIType *> *poiAdditionalsCategorized;
@property (nonatomic) NSArray<NSString *> *excludedPoiAdditionalCategories;
@property (nonatomic) NSString *poiAdditionalCategory;

- (instancetype)initWithName:(NSString *)name;

- (BOOL)isAdditional;
- (void)addPoiAdditional:(OAPOIType *)poiType;
- (void)addExcludedPoiAdditionalCategories:(NSArray<NSString *> *)excluded;

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) putTypes:(NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *)acceptedTypes;

- (void) setNonEditableOsm:(BOOL)nonEditableOsm;

+(NSMutableSet<NSString *> *)nullSet;
+(BOOL)isNullSet:(NSMutableSet<NSString *> *)set;

- (UIImage *)icon;
- (NSString *)iconName;

@end
