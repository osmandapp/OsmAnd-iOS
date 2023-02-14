//
//  OACloudAccountLogoutViewController.h
//  OsmAnd
//
//  Created by Skalii on 21.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OACloudAccountLogoutDelegate <NSObject>

@required

- (void)onLogout;

@end

@interface OACloudAccountLogoutViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OACloudAccountLogoutDelegate> logoutDelegate;

@end
