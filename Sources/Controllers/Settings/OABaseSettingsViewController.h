//
//  OABaseSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
#import "OABaseButtonsViewController.h"

@class OAApplicationMode;

@protocol OASettingsDataDelegate <NSObject>

- (void) onSettingsChanged;
- (void) closeSettingsScreenWithRouteInfo;
- (void) openNavigationSettings;

@end

@interface OABaseSettingsViewController : OABaseButtonsViewController<OASettingsDataDelegate>

@property (weak, nonatomic) id<OASettingsDataDelegate> delegate;
@property (nonatomic) OAApplicationMode *appMode;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;

@end
