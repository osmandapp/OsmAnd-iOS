//
//  OAAvoidRoadInfo.m
//  OsmAnd
//
//  Created by Alexey on 05.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAvoidRoadInfo.h"

@implementation OAAvoidRoadInfo

- (instancetype) initWithDict:(NSDictionary<NSString *,NSString *> *)dict
{
    self = [super init];
    if (self)
    {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        _roadId = [f numberFromString:dict[@"roadId"]].unsignedLongLongValue;
        float lat = dict[@"lat"].floatValue;
        float lon = dict[@"lon"].floatValue;
        _location = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        _name = dict[@"name"];
        _appModeKey = dict[@"appMode"];
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *) toDict
{
    NSMutableDictionary<NSString *, NSString *> *dict = [NSMutableDictionary dictionary];
    dict[@"roadId"] = [NSString stringWithFormat:@"%llu", self.roadId];
    dict[@"lat"] = [NSString stringWithFormat:@"%f", self.location.coordinate.latitude];
    dict[@"lon"] = [NSString stringWithFormat:@"%f", self.location.coordinate.longitude];
    dict[@"name"] = self.name;
    dict[@"appMode"] = self.appModeKey;
    return dict;
}

- (NSUInteger) hash
{
    NSInteger result = self.location.coordinate.latitude * 10000.0;
    result = 31 * result + (self.location.coordinate.longitude * 10000.0);
    result = 31 * result + [self.name hash];
    return result;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    
    if (![object isKindOfClass:[OAAvoidRoadInfo class]])
          return NO;
    
    OAAvoidRoadInfo *other = object;
    return [OAUtilities isCoordEqual:self.location.coordinate.latitude srcLon:self.location.coordinate.longitude destLat:other.location.coordinate.latitude destLon:other.location.coordinate.longitude] && (self.name == other.name || [self.name isEqualToString:other.name]);
}

@end
