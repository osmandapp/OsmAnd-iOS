//
//  OATopIndexFilter.m
//  OsmAnd Maps
//
//  Created by Ivan Pyrohivskyi on 26.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATopIndexFilter.h"

@implementation OATopIndexFilter

- (instancetype)initWithPoiSubType:(NSString *)poiSubType value:(NSString *)value {
    self = [super init];
    if (self) {
        _valueKey = [OATopIndexFilter getValueKey:value];
        _poiSubType = poiSubType;
        _value = value;
        _tag = [poiSubType stringByReplacingOccurrencesOfString:@"top_index_" withString:@""];
    }
    return self;
}

- (BOOL)acceptPoiSubType:(NSString *)poiSubType value:(NSString *)value {
    return [self.poiSubType isEqualToString:poiSubType] && [self.value isEqualToString:value];
}

- (NSString *)getTag {
    return self.tag;
}

- (NSString *)getName {
    return self.tag;
}

- (NSString *)getIconResource {
    return self.valueKey;
}

+ (NSString *)getValueKey:(NSString *)value {
    NSString *key = [[value lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    key = [key stringByReplacingOccurrencesOfString:@"'" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    key = [key stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return key;
}

@end
