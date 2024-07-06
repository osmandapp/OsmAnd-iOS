//
//  OAOsmAndLiveHelper.h
//  OsmAnd
//
//  Created by Paul on 12/13/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore/ResourcesManager.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ELiveUpdateFrequency)
{
    ELiveUpdateFrequencyUndefined = -1,
    ELiveUpdateFrequencyHourly = 0,
    ELiveUpdateFrequencyDaily,
    ELiveUpdateFrequencyWeekly
};

@interface OAOsmAndLiveHelper : NSObject

+ (BOOL) getPreferenceEnabledForLocalIndex:(NSString*) regionName;
+ (void) setPreferenceEnabledForLocalIndex:(NSString*) regionName value:(BOOL)value;

+ (BOOL) getPreferenceWifiForLocalIndex:(NSString*) regionName;
+ (void) setPreferenceWifiForLocalIndex:(NSString*) regionName value:(BOOL)value;

+ (ELiveUpdateFrequency) getPreferenceFrequencyForLocalIndex:(NSString*) regionName;
+ (void) setPreferenceFrequencyForLocalIndex:(NSString *) regionName value:(ELiveUpdateFrequency)value;

+ (NSTimeInterval) getPreferenceLastUpdateForLocalIndex:(NSString *) regionName;
+ (void) setPreferenceLastUpdateForLocalIndex:(NSString *) regionName value:(NSTimeInterval)value;

+ (void) setDefaultPreferencesForLocalIndex:(NSString *) regionName;
+ (void) removePreferencesForLocalIndex:(NSString *) regionName;

+ (NSString *)getFrequencyString:(ELiveUpdateFrequency)frequency;

+ (BOOL) isPreferencesInited:(NSString *)regionName;

+ (void)downloadUpdatesForRegion:(QString)regionName resourcesManager:(std::shared_ptr<OsmAnd::ResourcesManager>) resourcesManager checkUpdatesAsync:(BOOL)checkUpdatesAsync;

@end

NS_ASSUME_NONNULL_END
