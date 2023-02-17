//
//  OAWeatherCacheSettingsViewController.h
//  OsmAnd
//
//  Created by Skalii on 01.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

typedef NS_ENUM(NSInteger, EOAWeatherCacheType)
{
    EOAWeatherOnlineData = 0,
    EOAWeatherOfflineData
};

@class OAWorldRegion;

@protocol OAWeatherCacheSettingsDelegate <NSObject>

@required

- (void)onCacheClear;

@end

@interface OAWeatherCacheSettingsViewController : OABaseNavbarViewController

- (instancetype)initWithCacheType:(EOAWeatherCacheType)type;
- (instancetype)initWithRegion:(OAWorldRegion *)region;

@property (nonatomic, weak) id<OAWeatherCacheSettingsDelegate> cacheDelegate;

@end
