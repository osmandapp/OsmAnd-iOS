//
//  OARouteKey.m
//  OsmAnd Maps
//
//  Created by Paul on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARouteKey.h"
#import "OARouteKey+cpp.h"
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

static NSString *NETWORK_ROUTE_TYPE = @"type";


@interface OARouteKey()

@property (nonatomic) OsmAnd::NetworkRouteKey routeKey;
@property (nonatomic) OsmAnd::NetworkRouteKey type;

@end


@implementation OARouteKey

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key type:(const OsmAnd::OsmRouteType *)type
{
    self = [super init];
    if (self)
    {
        _routeKey = key;
        _localizedTitle = [self getLocalizedTitle];
        _type = type;
    }
    return self;
}

- (instancetype) initWithKey:(const OsmAnd::NetworkRouteKey &)key
{
    self = [self initWithKey:key type:OsmAnd::OsmRouteType::UNKNOWN];
    if (self)
    {
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

+ (OARouteKey *) fromGpxFile:(OASGpxFile *)gpxFile
{
    OASMutableDictionary<NSString *,NSString *> * networkRouteKeyTags = gpxFile.networkRouteKeyTags;
    NSString *type = networkRouteKeyTags[NETWORK_ROUTE_TYPE];
    if (!NSStringIsEmpty(type))
    {
        auto routeType = OsmAnd::OsmRouteType::getByTag(QString::fromNSString(type));
        if (routeType)
        {
            const auto routeKey = std::make_shared<OsmAnd::NetworkRouteKey>(routeType);
            routeKey->type = routeType;
            for (NSString *key in networkRouteKeyTags)
            {
                routeKey->addTag(QString::fromNSString(key), QString::fromNSString(networkRouteKeyTags[key]));
            }
            
            if (routeKey)
            {
                return [[OARouteKey alloc] initWithKey:*routeKey type:routeType];
            }
        }
    }
    
    OASMetadata * metadata = gpxFile.metadata;
    NSMutableDictionary<NSString *, NSString *> *combinedExtensionsTags = [NSMutableDictionary new];
    [combinedExtensionsTags addEntriesFromDictionary:[metadata getExtensionsToRead]];
    [combinedExtensionsTags addEntriesFromDictionary:[gpxFile getExtensionsToRead]];
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
        
        const auto routeType = OsmAnd::OsmRouteType::UNKNOWN;
        const auto routeKey = std::make_shared<OsmAnd::NetworkRouteKey>(routeType);
        routeKey->type = routeType;
        
        for (NSString *key in shieldTags)
        {
            routeKey->addTag(QString::fromNSString(key), QString::fromNSString(shieldTags[key]));
        }
        
        if (routeKey)
        {
            return [[OARouteKey alloc] initWithKey:*routeKey type:routeType];
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
    QMap<QString, QString> tagsToGpx = _routeKey.tagsMap();
    NSString *key = [NSString stringWithFormat:@"name:%@", [OAAppSettings sharedManager].settingPrefMapLanguage.get];
    NSString *result = tagsToGpx.value(QString::fromNSString(key)).toNSString();
    return result;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[OARouteKey allocWithZone:zone] initWithKey:_routeKey];
}

@end
