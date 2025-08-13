//
//  OATopIndexFilter.h
//  OsmAnd Maps
//
//  Created by Ivan Pyrohivskyi on 26.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASearchPoiTypeFilter.h"

@interface OATopIndexFilter : NSObject

@property (nonatomic, copy) NSString *poiSubType;
@property (nonatomic, copy) NSString *valueKey;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *value;

- (instancetype)initWithPoiSubType:(NSString *)poiSubType value:(NSString *)value;
- (BOOL)acceptPoiSubType:(NSString *)poiSubType value:(NSString *)value;
- (NSString *)getTag;
- (NSString *)getName;
- (NSString *)getIconResource;
+ (NSString *)getValueKey:(NSString *)value;
- (NSString *)getFilterId;
- (NSString *)getValue;

@end
