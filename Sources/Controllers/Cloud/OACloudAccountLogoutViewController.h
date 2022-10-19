//
//  OACloudAccountLogoutViewController.h
//  OsmAnd
//
//  Created by Skalii on 21.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@protocol OACloudAccountLogoutDelegate <NSObject>

@required

- (void)onLogout;

@end

@interface OACloudAccountLogoutViewController : OABaseSettingsViewController

@property (nonatomic, weak) id<OACloudAccountLogoutDelegate> logoutDelegate;

@end
