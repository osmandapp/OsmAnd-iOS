//
//  OARoutePreferencesScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OADashboardScreen.h"

typedef NS_ENUM(NSInteger, ERoutePreferencesScreen)
{
    ERoutePreferencesScreenUndefined = -1,
    ERoutePreferencesScreenMain = 0,
    //EMapSettingsScreenGpx,
};

@protocol OARoutePreferencesScreen <NSObject, OADashboardScreen, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, readonly) ERoutePreferencesScreen preferencesScreen;

@end
