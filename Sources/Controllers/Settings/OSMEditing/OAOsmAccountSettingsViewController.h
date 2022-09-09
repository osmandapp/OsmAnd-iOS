//
//  OAOsmAccountSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

typedef NS_ENUM(NSUInteger, EOAOSMAccountSettingsScreenType)
{
    EOAOSMAccountSettingsLoginScreenType = 0,
    EOAOSMAccountSettingsLoginOauthScreenType,
    EOAOSMAccountSettingsLogoutScreenType,
};

@protocol OAAccountSettingDelegate <NSObject>

- (void) onAccountInformationUpdated;

@end

@interface OAOsmAccountSettingsViewController : OABaseSettingsViewController

@property (nonatomic, weak) id<OAAccountSettingDelegate> accountDelegate;

@end
