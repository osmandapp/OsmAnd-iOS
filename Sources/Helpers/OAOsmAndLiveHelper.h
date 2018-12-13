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

@interface OAOsmAndLiveHelper : NSObject

+ (BOOL) getPreferenceEnabledForLocalIndex:(NSString*) regionName;
+ (void) setPreferenceEnabledForLocalIndex:(NSString*) regionName value:(BOOL)value;

+ (BOOL) getPreferenceWifiForLocalIndex:(NSString*) regionName;
+ (void) setPreferenceWifiForLocalIndex:(NSString*) regionName value:(BOOL)value;

+ (NSInteger) getPreferenceFrequencyForLocalIndex:(NSString*) regionName;
+ (void) setPreferenceFrequencyForLocalIndex:(NSString *) regionName value:(NSInteger)value;

+ (double) getPreferenceLastUpdateForLocalIndex:(NSString *) regionName;
+ (void) setPreferenceLastUpdateForLocalIndex:(NSString *) regionName value:(double)value;

+ (void) setDefaultPreferencesForLocalIndex:(NSString *) regionName;
+ (void) removePreferencesForLocalIndex:(NSString *) regionName;

+ (void)downloadUpdatesForRegion:(QString)regionName resourcesManager:(std::shared_ptr<OsmAnd::ResourcesManager>) resourcesManager;

@end

NS_ASSUME_NONNULL_END
