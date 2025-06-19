//
//  OARouteKey.m
//  OsmAnd Maps
//
//  Created by Paul on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteKey.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

static NSDictionary<NSString *, NSString *> *SHIELD_TO_OSMC = @{
    @"shield_bg": @"osmc_background",
    @"shield_fg": @"osmc_foreground",
    @"shield_fg_2": @"osmc_foreground2",
    @"shield_textcolor": @"osmc_textcolor",
    @"shield_text": @"osmc_text"
};


@implementation OARouteKey

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key
{
    self = [super init];
    if (self) {
        _routeKey = key;
        _localizedTitle = [self getLocalizedTitle];
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

+ (OARouteKey *) fromGpx:(OASGpxFile *)gpx
{
    OASMutableDictionary<NSString *,NSString *> * networkRouteKeyTags = gpx.networkRouteKeyTags;
    QMap<QString, QString> tags;
    for (NSString *key in networkRouteKeyTags)
        tags.insert(QString::fromNSString(key), QString::fromNSString(networkRouteKeyTags[key]));
    
    auto rk = OsmAnd::NetworkRouteKey::fromGpx(tags);
    if (rk)
    {
        auto key = *rk;
        return [[OARouteKey alloc] initWithKey:key];
    }
    
    OASMetadata * metadata = gpx.metadata;
    NSMutableDictionary<NSString *, NSString *> *combinedExtensionsTags = [NSMutableDictionary new];
    [combinedExtensionsTags addEntriesFromDictionary:[metadata getExtensionsToRead]];
    [combinedExtensionsTags addEntriesFromDictionary:[gpx getExtensionsToRead]];
    return [self.class fromShieldTags:combinedExtensionsTags];
}

+ (OARouteKey *) fromShieldTags:(NSMutableDictionary<NSString *, NSString *> *)shieldTags
{
    if (!NSDictionaryIsEmpty(shieldTags))
    {
        for (NSString *shield in SHIELD_TO_OSMC)
        {
            NSString *osmc = SHIELD_TO_OSMC[shield];
            NSString *value = shieldTags[shield];
            if (value)
            {
                value = [value stringByReplacingOccurrencesOfString:@"^osmc_"
                                                         withString:@""
                                                            options:NSRegularExpressionSearch
                                                              range:NSMakeRange(0, value.length)];
                
                value = [value stringByReplacingOccurrencesOfString:@"_bg$"
                                                         withString:@""
                                                            options:NSRegularExpressionSearch
                                                              range:NSMakeRange(0, value.length)];
                
                shieldTags[osmc] = value;
            }
        }
            
        QMap<QString, QString> tags;
        tags.insert("type", OsmAnd::OsmRouteType::UNKNOWN->name);
        
        for (NSString *key in shieldTags)
            tags.insert(QString::fromNSString(key), QString::fromNSString(shieldTags[key]));
        
        auto rk = OsmAnd::NetworkRouteKey::fromGpx(tags);
        if (rk)
        {
            auto key = *rk;
            return [[OARouteKey alloc] initWithKey:key];
        }
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

- (NSString *)getLocalizedTitle
{
    QMap<QString, QString> tagsToGpx = _routeKey.tagsToGpx();
    NSString *key = [NSString stringWithFormat:@"name:%@", [OAAppSettings sharedManager].settingPrefMapLanguage.get];
    NSString *result = tagsToGpx.value(QString::fromNSString(key)).toNSString();
    return result;
}

- (id)copyWithZone:(NSZone *)zone
{
    OARouteKey *copy = [[OARouteKey allocWithZone:zone] initWithKey:_routeKey];
    return copy;
}

@end
