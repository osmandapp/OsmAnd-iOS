//
//  OATopIndexFilter.h
//  OsmAnd Maps
//
//  Created by Ivan Pyrohivskyi on 26.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASearchPoiTypeFilter.h"


@interface OATopIndexFilter : NSObject /*: SearchPoiAdditionalFilter */

@property (nonatomic, strong) NSString *poiSubType;
@property (nonatomic, copy) NSString *valueKey;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *value;

- (instancetype)initWithPoiSubType:(NSString *)poiSubType value:(NSString *)value;
- (BOOL)acceptPoiSubType:(NSString *)poiSubType value:(NSString *)value;
- (NSString *)getTag;
- (NSString *)getName;
- (NSString *)getIconResource;
+ (NSString *)getValueKey:(NSString *)value;

@end
