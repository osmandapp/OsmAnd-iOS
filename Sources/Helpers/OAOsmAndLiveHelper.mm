//
//  OAOsmAndLiveHelper.m
//  OsmAnd
//
//  Created by Paul on 12/13/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveHelper.h"
#import "OAResourcesBaseViewController.h"
#include "Localization.h"
#import "Reachability.h"

#define kLiveUpdatesOnPrefix @"live_updates_on_"
#define kLiveUpdatesWifiPrefix @"download_via_wifi_"
#define kLiveUpdatesFrequencyPrefix @"update_times_"
#define kLiveUpdatesLastUpdatePrefix @"ast_update_attempt_"

#define kLiveUpdateFrequencyHour 3600
#define kLiveUpdateFrequencyDay 86400
#define kLiveUpdateFrequencyWeek 604800

//private static final String UPDATE_TIMES_POSTFIX = "_update_times";
//private static final String TIME_OF_DAY_TO_UPDATE_POSTFIX = "_time_of_day_to_update";
//private static final String DOWNLOAD_VIA_WIFI_POSTFIX = "_download_via_wifi";
//private static final String LIVE_UPDATES_ON_POSTFIX = "_live_updates_on";
//private static final String LAST_UPDATE_ATTEMPT_ON_POSTFIX = "_last_update_attempt";
//public static final String LOCAL_INDEX_INFO = "local_index_info";

@implementation OAOsmAndLiveHelper

+ (BOOL) getPreferenceEnabledForLocalIndex:(NSString*)regionName
{
    NSString *prefKey = [kLiveUpdatesOnPrefix stringByAppendingString:regionName];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults]
                                                                    boolForKey:prefKey] : NO;
}

+ (void) setPreferenceEnabledForLocalIndex:(NSString*)regionName value:(BOOL)value
{
    NSString *prefKey = [kLiveUpdatesOnPrefix stringByAppendingString:regionName];
    [[NSUserDefaults standardUserDefaults] setBool:value
                                                   forKey:prefKey];
}

+ (BOOL) getPreferenceWifiForLocalIndex:(NSString*)regionName
{
    NSString *prefKey = [kLiveUpdatesWifiPrefix stringByAppendingString:regionName];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults]
                                                                           boolForKey:prefKey] : NO;
}

+ (void) setPreferenceWifiForLocalIndex:(NSString*)regionName value:(BOOL)value
{
    NSString *prefKey = [kLiveUpdatesWifiPrefix stringByAppendingString:regionName];
    [[NSUserDefaults standardUserDefaults] setBool:value
                                                   forKey:prefKey];
}

+ (ELiveUpdateFrequency) getPreferenceFrequencyForLocalIndex:(NSString*)regionName
{
    NSString *prefKey = [kLiveUpdatesFrequencyPrefix stringByAppendingString:regionName];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? (ELiveUpdateFrequency) [[NSUserDefaults standardUserDefaults]
                                                                           integerForKey:prefKey] : ELiveUpdateFrequencyUndefined;
}

+ (void) setPreferenceFrequencyForLocalIndex:(NSString *)regionName value:(ELiveUpdateFrequency)value
{
    NSString *prefKey = [kLiveUpdatesFrequencyPrefix stringByAppendingString:regionName];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefKey];
}

+ (NSTimeInterval) getPreferenceLastUpdateForLocalIndex:(NSString *)regionName
{
    NSString *prefKey = [kLiveUpdatesLastUpdatePrefix stringByAppendingString:regionName];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults]
                                                                                       doubleForKey:prefKey] : -1.0;
}

+ (void) setPreferenceLastUpdateForLocalIndex:(NSString *)regionName value:(NSTimeInterval)value
{
    NSString *prefKey = [kLiveUpdatesLastUpdatePrefix stringByAppendingString:regionName];
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:prefKey];
}

+ (void) setDefaultPreferencesForLocalIndex:(NSString *)regionName
{
    [OAOsmAndLiveHelper setPreferenceEnabledForLocalIndex:regionName value:YES];
    [OAOsmAndLiveHelper setPreferenceWifiForLocalIndex:regionName value:NO];
    [OAOsmAndLiveHelper setPreferenceFrequencyForLocalIndex:regionName value:ELiveUpdateFrequencyHourly];
    [OAOsmAndLiveHelper setPreferenceLastUpdateForLocalIndex:regionName value:-1.0];
}

+ (void) removePreferencesForLocalIndex:(NSString *)regionName
{
    for (NSString *key in [self getPrefKeys:regionName])
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

+ (NSArray<NSString *> *)getPrefKeys:(NSString *)regionName
{
    NSMutableArray<NSString *> *keys = [[NSMutableArray alloc] init];
    [keys addObject:[kLiveUpdatesLastUpdatePrefix stringByAppendingString:regionName]];
    [keys addObject:[kLiveUpdatesOnPrefix stringByAppendingString:regionName]];
    [keys addObject:[kLiveUpdatesWifiPrefix stringByAppendingString:regionName]];
    [keys addObject:[kLiveUpdatesFrequencyPrefix stringByAppendingString:regionName]];
    return keys;
}

+ (NSString *)getFrequencyString:(ELiveUpdateFrequency)frequency
{
    switch (frequency) {
        case ELiveUpdateFrequencyHourly:
            return OALocalizedString(@"osmand_live_hourly");
            break;
        case ELiveUpdateFrequencyDaily:
            return OALocalizedString(@"osmand_live_daily");
            break;
        case ELiveUpdateFrequencyWeekly:
            return OALocalizedString(@"osmand_live_weekly");
            break;
            
        default:
            return @"";
            break;
    }
}

+ (void)downloadUpdatesForRegion:(QString)regionName resourcesManager:(std::shared_ptr<OsmAnd::ResourcesManager>) resourcesManager
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *regionNameStr = regionName.toNSString();
        if ([OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:regionNameStr])
        {
            NetworkStatus status = [Reachability reachabilityForInternetConnection].currentReachabilityStatus;
            BOOL downloadOnlyViaWiFi = [OAOsmAndLiveHelper getPreferenceWifiForLocalIndex:regionNameStr];
            if (status == NotReachable || (status != ReachableViaWiFi && downloadOnlyViaWiFi))
                return;

            NSTimeInterval updateTime = [OAOsmAndLiveHelper getPreferenceLastUpdateForLocalIndex:regionNameStr];
            ELiveUpdateFrequency updateFrequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:regionNameStr];
            NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:updateTime];
            int seconds = -[lastUpdateDate timeIntervalSinceNow];
            int secondsRequired = updateFrequency == ELiveUpdateFrequencyHourly ? kLiveUpdateFrequencyHour : updateFrequency == ELiveUpdateFrequencyDaily ? kLiveUpdateFrequencyDay : kLiveUpdateFrequencyWeek;
            if (seconds > secondsRequired || updateTime == -1.0)
            {
                const auto& lst = resourcesManager->changesManager->
                getUpdatesByMonth(regionName);
                for (const auto& res : lst->getItemsForUpdate())
                {
                    [OAResourcesBaseViewController startBackgroundDownloadOf:res];
                }
                [OAOsmAndLiveHelper setPreferenceLastUpdateForLocalIndex:regionNameStr value:
                    [[NSDate date] timeIntervalSince1970]];
            }
        }
    });
}

@end
