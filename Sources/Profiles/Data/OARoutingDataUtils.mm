//
//  OARoutingDataUtils.m
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARoutingDataUtils.h"
#import "OARoutingDataObject.h"
#import "OARoutingProfilesHolder.h"
#import "OARoutingFile.h"
#import "OAProfilesGroup.h"
#import "Localization.h"
#import "OsmAndApp.h"

#define kOsmAndNavigation @"osmand_navigation"
#define kDerivedProfiles "derivedProfiles"
#define kGeocoding @"geocoding"

@implementation OARoutingDataUtils

+ (NSArray<OAProfilesGroup *> *)getOfflineProfiles
{
    NSMutableArray<OAProfilesGroup *> *result = [NSMutableArray array];
    NSMutableDictionary<NSString *, OARoutingFile *> *routingFiles = [self getOfflineRoutingFilesByNames];
    
    OAProfilesGroup *profilesGroup = [self createProfilesGroup:OALocalizedString(@"osmand_default_routing") file:routingFiles[kOsmAndNavigation]];
    [routingFiles removeObjectForKey:kOsmAndNavigation];
    if (profilesGroup)
        [result addObject:profilesGroup];
    
    for (NSString *key in routingFiles.allKeys)
    {
        profilesGroup = [self createProfilesGroup:key file:routingFiles[key]];
        if (profilesGroup)
            [result addObject:profilesGroup];
    }
    [result addObject:[[OAProfilesGroup alloc] initWithTitle:OALocalizedString(@"shared_string_external") profiles:[self getExternalRoutingProfiles]]];
    [self sortItems:result];
    return result;
}

+ (OAProfilesGroup *)createProfilesGroup:(NSString *)title file:(OARoutingFile *)file
{
    return file ? [[OAProfilesGroup alloc] initWithTitle:title profiles:file.profiles] : nil;
}

//public List<ProfilesGroup> getOnlineProfiles(@Nullable List<ProfilesGroup> predefined) {
//        List<ProfilesGroup> result = new ArrayList<>();
//        if (!Algorithms.isEmpty(predefined)) {
//            result.addAll(predefined);
//        }
//        result.add(new ProfilesGroup(getString(R.string.shared_string_custom), getOnlineRoutingProfiles(true)));
//        sortItems(result);
//        return result;
//    }

+ (OARoutingProfilesHolder *)getRoutingProfiles
{
    NSMutableArray<OARoutingDataObject *> *profiles = [NSMutableArray array];
    [profiles addObjectsFromArray:[self getOfflineRoutingProfiles]];
    [profiles addObjectsFromArray:[self getExternalRoutingProfiles]];
    //    profiles.addAll(getOnlineRoutingProfiles(false));
    
    OARoutingProfilesHolder *result = [OARoutingProfilesHolder new];
    for (OARoutingDataObject *profile in profiles)
    {
        [result add:profile];
    }
    return result;
}

+ (NSMutableDictionary<NSString *, OARoutingFile *> *)getOfflineRoutingFilesByNames
{
    NSMutableDictionary<NSString *, OARoutingFile *> *map = [NSMutableDictionary dictionary];
    for (OARoutingDataObject *profile in [self getOfflineRoutingProfiles])
    {
        NSString *fileName = profile.fileName;
        if (!fileName || fileName.length == 0)
            fileName = kOsmAndNavigation;
        OARoutingFile *file = map[fileName];
        if (!file)
        {
            file = [[OARoutingFile alloc] initWithFileName:fileName];
            map[fileName] = file;
        }
        [file addProfile:profile];
    }
    return map;
}

+ (NSArray<OARoutingDataObject *> *)getOfflineRoutingProfiles
{
    NSMutableArray<OARoutingDataObject *> *result = [NSMutableArray array];
    [result addObject:[[OARoutingDataObject alloc] initWithStringKey:[OARoutingDataObject getProfileKey:EOARoutingProfilesResourceStraightLine]
                                                                name:[OARoutingDataObject getLocalizedName:EOARoutingProfilesResourceStraightLine]
                                                               descr:OALocalizedString(@"special_routing_type")
                                                            iconName:[OARoutingDataObject getIconName:EOARoutingProfilesResourceStraightLine]
                                                          isSelected:NO
                                                            fileName:nil
                                                      derivedProfile:nil]];
    [result addObject:[[OARoutingDataObject alloc] initWithStringKey:[OARoutingDataObject getProfileKey:EOARoutingProfilesResourceDirectTo]
                                                                name:[OARoutingDataObject getLocalizedName:EOARoutingProfilesResourceDirectTo]
                                                               descr:OALocalizedString(@"special_routing_type")
                                                            iconName:[OARoutingDataObject getIconName:EOARoutingProfilesResourceDirectTo]
                                                          isSelected:NO
                                                            fileName:nil
                                                      derivedProfile:nil]];
    
    NSArray<NSString *> *disabledRouterNames = @[]; //OsmandPlugin.getDisabledRouterNames();
    for (const auto& builder : [[OsmAndApp instance] getAllRoutingConfigs])
    {
        for (auto it = builder->routers.begin(); it != builder->routers.end(); ++it)
        {
            NSString *routerKey = [NSString stringWithCString:it->first.c_str() encoding:NSUTF8StringEncoding];
            const auto router = it->second;
            if (router != nullptr && ![routerKey isEqualToString:kGeocoding] && ![disabledRouterNames containsObject:routerKey])
            {
                NSString *iconName = @"ic_custom_navigation";
                NSString *name = [NSString stringWithCString:router->profileName.c_str() encoding:NSUTF8StringEncoding];
                NSString *fileName = [NSString stringWithCString:router->fileName.c_str() encoding:NSUTF8StringEncoding];
                fileName = [fileName containsString:@"OsmAnd Maps.app"] ? @"" : fileName;
                NSString *descr = OALocalizedString(@"osmand_default_routing");
                if (fileName && fileName.length > 0)
                {
                    descr = fileName;
                }
                else if ([OARoutingDataObject isRpValue:name.upperCase])
                {
                    iconName = [OARoutingDataObject getIconName:[OARoutingDataObject getValueOf:name.upperCase]];
                    name = [OARoutingDataObject getLocalizedName:[OARoutingDataObject getValueOf:name.upperCase]];
                }
                OARoutingDataObject *data = [[OARoutingDataObject alloc] initWithStringKey:routerKey
                                                                                      name:name
                                                                                     descr:descr
                                                                                  iconName:iconName
                                                                                isSelected:NO
                                                                                  fileName:fileName
                                                                            derivedProfile:nil];
                [result addObject:data];
                const auto& derivedProfiles = router->getAttribute(kDerivedProfiles);
                if (!derivedProfiles.empty())
                {
                    for (const auto& s : split_string(derivedProfiles, ","))
                    {
                        if (s == "default")
                            continue;
                        
                        [result addObject:[self createDerivedProfile:data
                                                      derivedProfile:[NSString stringWithUTF8String:s.c_str()]]];
                    }
                }
            }
        }
    }
    return result;
}

+ (OARoutingDataObject *)createDerivedProfile:(OARoutingDataObject *)original derivedProfile:(NSString *)derivedProfile
{
    NSString *translationKey = [NSString stringWithFormat:@"app_mode_%@", derivedProfile];
    NSString *localizedProfileName = OALocalizedString(translationKey);
    NSString *name = [translationKey isEqualToString:localizedProfileName] ? [translationKey capitalizedString] : localizedProfileName;
    NSString *iconName = [self getIconNameForDerivedProfile:derivedProfile];
    return [[OARoutingDataObject alloc] initWithStringKey:original.stringKey
                                                     name:name
                                                    descr:original.descr
                                                 iconName:iconName
                                               isSelected:original.isSelected
                                                 fileName:original.fileName
                                           derivedProfile:derivedProfile];
}

+ (NSString *) getIconNameForDerivedProfile:(NSString *)derivedProfile
{
    NSString *imgKey = [NSString stringWithFormat:@"ic_action_%@", derivedProfile];
    UIImage *testImg = [UIImage imageNamed:imgKey];
    if (testImg)
    {
        return imgKey;
    }
    else
    {
        // We need to check twice for legacy reasons: some icons have the _dark suffix
        imgKey = [imgKey stringByAppendingString:@"_dark"];
        testImg = [UIImage imageNamed:imgKey];
        if (testImg)
            return imgKey;
    }
    return @"ic_custom_navigation";
}

+ (NSArray<OARoutingDataObject *> *)getExternalRoutingProfiles
{
    NSMutableArray<OARoutingDataObject *> *result = [NSMutableArray array];
    //    if (app.getBRouterService() != null) {
    //        result.add(new RoutingDataObject(BROUTER_MODE.name(),
    //                getString(BROUTER_MODE.getStringRes()),
    //                getString(R.string.third_party_routing_type),
    //                BROUTER_MODE.getIconRes(),
    //                false, null, null));
    //    }
    return result;
}

//public ProfileDataObject getOnlineEngineByKey(String stringKey) {
//        OnlineRoutingHelper helper = app.getOnlineRoutingHelper();
//        OnlineRoutingEngine engine = helper.getEngineByKey(stringKey);
//        if (engine != null) {
//            return convertOnlineEngineToDataObject(engine);
//        }
//        return null;
//    }

//private List<RoutingDataObject> getOnlineRoutingProfiles(boolean onlyCustom) {
//        OnlineRoutingHelper helper = app.getOnlineRoutingHelper();
//        List<RoutingDataObject> objects = new ArrayList<>();
//        List<OnlineRoutingEngine> engines = onlyCustom ? helper.getOnlyCustomEngines() : helper.getEngines();
//        for (int i = 0; i < engines.size(); i++) {
//            OnlineRoutingDataObject profile = convertOnlineEngineToDataObject(engines.get(i));
//            profile.setOrder(i);
//            objects.add(profile);
//        }
//        return objects;
//    }

//private OnlineRoutingDataObject convertOnlineEngineToDataObject(OnlineRoutingEngine engine) {
//        return new OnlineRoutingDataObject(engine.getName(app),
//                engine.getBaseUrl(), engine.getStringKey(), R.drawable.ic_world_globe_dark);
//    }

//    public void downloadPredefinedEngines(CallbackWithObject<String> callback) {
//        new Thread(() -> {
//            String content = null;
//            try {
//                content = app.getOnlineRoutingHelper().makeRequest(DOWNLOAD_ENGINES_URL);
//            } catch (IOException e) {
//                LOG.error("Error trying download predefined routing engines list: " + e.getMessage());
//            }
//            String result = content;
//            app.runInUIThread(() -> callback.processResult(result));
//        }).start();
//    }
//
//    public List<ProfilesGroup> parsePredefinedEngines(String content) {
//        try {
//            return parsePredefinedEnginesImpl(content);
//        } catch (JSONException e) {
//            LOG.error("Error trying parse JSON: " + e.getMessage());
//        }
//        return null;
//    }

//    private List<ProfilesGroup> parsePredefinedEnginesImpl(String content) throws JSONException {
//        JSONObject root = new JSONObject(content);
//        JSONArray providers = root.getJSONArray(PROVIDERS);
//        List<ProfilesGroup> result = new ArrayList<>();
//        for (int i = 0; i < providers.length(); i++) {
//            JSONObject groupObject = providers.getJSONObject(i);
//            String providerName = groupObject.getString(NAME);
//            String providerType = groupObject.getString(TYPE);
//            String providerUrl = groupObject.getString(URL);
//            JSONArray items = groupObject.getJSONArray(ROUTES);
//            List<RoutingDataObject> engines = new ArrayList<>();
//            for (int j = 0; j < items.length(); j++) {
//                JSONObject item = items.getJSONObject(j);
//                String engineName = item.getString(NAME);
//                String engineUrl = item.getString(URL);
//                int iconRes = R.drawable.ic_world_globe_dark;
//                String type = item.getString(TYPE).toUpperCase();
//                if (RoutingProfilesResources.isRpValue(type)) {
//                    iconRes = RoutingProfilesResources.valueOf(type).getIconRes();
//                    engineName = getString(RoutingProfilesResources.valueOf(type).getStringRes());
//                }
//                String key = OnlineRoutingEngine.generatePredefinedKey(providerName, type);
//                OnlineRoutingDataObject engine = new OnlineRoutingDataObject(engineName, engineUrl, key, iconRes);
//                engines.add(engine);
//            }
//            ProfilesGroup group = new PredefinedProfilesGroup(providerName, providerType, engines);
//            group.setDescription(providerUrl);
//            result.add(group);
//        }
//        return result;
//    }

+ (void)sortItems:(NSMutableArray<OAProfilesGroup *> *)groups
{
    for (OAProfilesGroup *group in groups)
    {
        NSArray<OARoutingDataObject *> *profiles = group.profiles;
        if (profiles && profiles.count > 0)
            [group sortProfiles];
    }
}

@end
