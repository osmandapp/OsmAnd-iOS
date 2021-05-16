//
//  OAProfileDataUtils.m
//  OsmAnd
//
//  Created by nnngrach on 28.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileDataUtils.h"
#import "OAProfileDataObject.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OsmAndApp.h"

#define kOsmAndNavigation @"osmand_navigation"

@implementation OAProfileDataUtils

+ (NSArray<OAProfileDataObject *> *) getDataObjects:(NSArray<OAApplicationMode *> *)appModes
{
    NSMutableArray<OAProfileDataObject *> *profiles = [NSMutableArray new];
    for (OAApplicationMode *mode in appModes)
    {
        NSString *description = mode.descr;
        if (!description || description.length == 0)
            description = [self getAppModeDescription:mode];
        
        OAProfileDataObject *profile = [[OAProfileDataObject alloc] initWithStringKey:mode.stringKey name:[mode toHumanString] descr:description iconName:mode.getIconName isSelected:NO];
        profile.iconColor = mode.getIconColor;
        [profiles addObject:profile];
    }
    return profiles;
}

+ (NSString *) getAppModeDescription:(OAApplicationMode *)mode
{
    if (mode.isCustomProfile)
        return OALocalizedString(@"profile_type_user_string");
    else
        return OALocalizedString(@"profile_type_osmand_string");
}

+ (NSDictionary<NSString *, OARoutingProfileDataObject *> *) getRoutingProfiles
{
    NSMutableDictionary<NSString *, OARoutingProfileDataObject *> *profilesObjects = [NSMutableDictionary new];
    OARoutingProfileDataObject *straightLine = [[OARoutingProfileDataObject alloc] initWithResource:EOARoutingProfilesResourceStraightLine];
    straightLine.descr = OALocalizedString(@"special_routing");
    [profilesObjects setObject:straightLine forKey:[OARoutingProfileDataObject getProfileKey:EOARoutingProfilesResourceStraightLine]];
    
    OARoutingProfileDataObject *directTo = [[OARoutingProfileDataObject alloc] initWithResource:EOARoutingProfilesResourceDirectTo];
    directTo.descr = OALocalizedString(@"special_routing");
    [profilesObjects setObject:directTo forKey:[OARoutingProfileDataObject getProfileKey:EOARoutingProfilesResourceDirectTo]];
    
//    if (context.getBRouterService() != null) {
//        profilesObjects.put(RoutingProfilesResources.BROUTER_MODE.name(), new RoutingProfileDataObject(
//                RoutingProfilesResources.BROUTER_MODE.name(),
//                context.getString(RoutingProfilesResources.BROUTER_MODE.getStringRes()),
//                context.getString(R.string.third_party_routing_type),
//                RoutingProfilesResources.BROUTER_MODE.getIconRes(),
//                false, null));
//    }

//    List<String> disabledRouterNames = OsmandPlugin.getDisabledRouterNames();
    for (const auto& builder : OsmAndApp.instance.getAllRoutingConfigs)
        [self collectRoutingProfilesFromConfig:builder profileObjects:profilesObjects disabledRouterNames:@[]];
    return profilesObjects;
}

+ (void) collectRoutingProfilesFromConfig:(std::shared_ptr<RoutingConfigurationBuilder>) builder
                           profileObjects:(NSMutableDictionary<NSString *, OARoutingProfileDataObject *> *) profilesObjects disabledRouterNames:(NSArray<NSString *> *) disabledRouterNames
{
    for (auto it = builder->routers.begin(); it != builder->routers.end(); ++it)
    {
        NSString *routerKey = [NSString stringWithCString:it->first.c_str() encoding:NSUTF8StringEncoding];
        const auto router = it->second;
        if (router != nullptr && ![routerKey isEqualToString:@"geocoding"] && ![disabledRouterNames containsObject:routerKey])
        {
            NSString *iconName = @"ic_custom_navigation";
            NSString *name = [NSString stringWithCString:router->profileName.c_str() encoding:NSUTF8StringEncoding];
            NSString *descr = OALocalizedString(@"osmand_routing");
            NSString *fileName = [NSString stringWithCString:router->fileName.c_str() encoding:NSUTF8StringEncoding];
            fileName = [fileName containsString:@"OsmAnd Maps.app"] ? @"" : fileName;
            if (fileName.length > 0)
            {
                descr = fileName;
                OARoutingProfileDataObject *data = [[OARoutingProfileDataObject alloc] initWithStringKey:routerKey name:name descr:descr iconName:iconName isSelected:NO fileName:fileName];
                [profilesObjects setObject:data forKey:routerKey];
            }
            else if ([OARoutingProfileDataObject isRpValue:name.upperCase])
            {
                OARoutingProfileDataObject *data = [OARoutingProfileDataObject getRoutingProfileDataByName:name.upperCase];
                data.descr = descr;
                data.stringKey = name;
                [profilesObjects setObject:data forKey:routerKey];
            }
        }
    }
}

//public static List<ProfileDataObject> getBaseProfiles(OsmandApplication app) {
//    return getBaseProfiles(app, false);
//}
//
//public static List<ProfileDataObject> getBaseProfiles(OsmandApplication app, boolean includeBrowseMap) {
//    List<ProfileDataObject> profiles = new ArrayList<>();
//    for (ApplicationMode mode : ApplicationMode.allPossibleValues()) {
//        if (mode != ApplicationMode.DEFAULT || includeBrowseMap) {
//            String description = mode.getDescription();
//            if (Algorithms.isEmpty(description)) {
//                description = getAppModeDescription(app, mode);
//            }
//            profiles.add(new ProfileDataObject(mode.toHumanString(), description,
//                    mode.getStringKey(), mode.getIconRes(), false, mode.getIconColorInfo()));
//        }
//    }
//    return profiles;
//}

+ (NSArray<OARoutingProfileDataObject *> *) getSortedRoutingProfiles
{
    NSMutableArray<OARoutingProfileDataObject *> *result = [NSMutableArray new];
    NSDictionary<NSString *, NSArray<OARoutingProfileDataObject *> *> *routingProfilesByFileNames = [self getRoutingProfilesByFileNames];
    NSArray<NSString *> *fileNames = routingProfilesByFileNames.allKeys;
    NSArray<NSString *> *sortedNames = [fileNames sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 isEqualToString:kOsmAndNavigation] ? NSOrderedAscending : [obj2 isEqualToString:kOsmAndNavigation] ? NSOrderedDescending : [obj1 compare:obj2];
    }];
    
    for (NSString *fileName in sortedNames)
    {
        NSArray<OARoutingProfileDataObject *> *routingProfilesFromFile = routingProfilesByFileNames[fileName];
        if (routingProfilesFromFile)
        {
            NSArray<OARoutingProfileDataObject *> *sortedElements = [routingProfilesFromFile sortedArrayUsingComparator:^NSComparisonResult(OARoutingProfileDataObject *obj1, OARoutingProfileDataObject *obj2) {
                return [obj1 compare:obj2];
            }];
            [result addObjectsFromArray:sortedElements];
        }
    }
    return result;
}

+ (NSDictionary<NSString *, NSArray<OARoutingProfileDataObject *> *> *) getRoutingProfilesByFileNames
{
    NSMutableDictionary<NSString *, NSMutableArray<OARoutingProfileDataObject *> *> *res = [[NSMutableDictionary alloc] init];
    for (OARoutingProfileDataObject *profile in [self getRoutingProfiles].allValues)
    {
        NSString *fileName = profile.fileName != nil && profile.fileName.length > 0 ? profile.fileName : kOsmAndNavigation;
        if (res[fileName]) {
            [res[fileName] addObject:profile];
        }
        else
        {
            [res setObject:[NSMutableArray arrayWithObject:profile] forKey:fileName];
        }
    }
    return res;
}

@end
