//
//  OARouteKey.m
//  OsmAnd Maps
//
//  Created by Paul on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteKey.h"
#import "Localization.h"

@implementation OARouteKey

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key
{
    self = [super init];
    if (self) {
        _routeKey = key;
    }
    return self;
}


- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object)
        return NO;
    
    if ([object isKindOfClass:self.class])
    {
        OARouteKey *other = (OARouteKey *)object;
        return self.routeKey == other.routeKey;
    }
    return NO;
}

- (NSUInteger) hash
{
    return self.routeKey.operator int();
}

+ (OARouteKey *) fromGpx:(NSDictionary<NSString *, NSString *> *)gpx
{
    QMap<QString, QString> tags;
    for (NSString *key in gpx)
        tags.insert(QString::fromNSString(key), QString::fromNSString(gpx[key]));
    
    auto rk = OsmAnd::NetworkRouteKey::fromGpx(tags);
    if (rk)
    {
        auto key = *rk;
        return [[OARouteKey alloc] initWithKey:key];
    }
    return nil;
}

- (NSString *)getActivityTypeTitle
{
    NSString *tag = _routeKey.getTag().toNSString();
    NSString *resourceId = [NSString stringWithFormat:@"%@%@%@", @"activity_type_", tag, @"_name"];
    NSString *res = OALocalizedString(resourceId);
    return [res isEqualToString:resourceId] ? [OAUtilities capitalizeFirstLetter:tag] : res;
}

@end
