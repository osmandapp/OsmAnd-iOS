//
//  OATopIndexFilter.m
//  OsmAnd Maps
//
//  Created by Ivan Pyrohivskyi on 26.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATopIndexFilter.h"
#import "OAPOIBaseType.h"
#import "OAPOIHelper.h"

@implementation OATopIndexFilter

- (instancetype)initWithPoiSubType:(NSString *)poiSubType value:(NSString *)value 
{
    self = [super init];
    if (self) 
    {
        _valueKey = [OATopIndexFilter getValueKey:value];
        _poiSubType = poiSubType;
        _value = value;
        _tag = [poiSubType stringByReplacingOccurrencesOfString:@"top_index_" withString:@""];
    }
    return self;
}

- (BOOL)acceptPoiSubType:(NSString *)poiSubType value:(NSString *)value 
{
    return [self.poiSubType isEqualToString:poiSubType] && [self.value isEqualToString:value];
}

- (NSString *)getTag 
{
    return self.tag;
}

- (NSString *)getFilterId 
{
    return [NSString stringWithFormat:@"%@%@_%@", @"top_index_", self.tag, [OATopIndexFilter getValueKey:self.value]];
}

- (NSString *)getName
{
    OAPOIBaseType *pt = [[OAPOIHelper sharedInstance] getAnyPoiAdditionalTypeByKey:_tag];
    if (pt)
        return pt.nameLocalized;
    
    return [[OAPOIHelper sharedInstance] getPhraseByName:_tag];
}

- (NSString *)getValue 
{
    return self.value;
}

- (NSString *)getIconResource 
{
    return @"ic_custom_search";
}

+ (NSString *)getValueKey:(NSString *)value 
{
    NSString *key = [[value lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    key = [key stringByReplacingOccurrencesOfString:@"'" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    key = [key stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return key;
}

@end
