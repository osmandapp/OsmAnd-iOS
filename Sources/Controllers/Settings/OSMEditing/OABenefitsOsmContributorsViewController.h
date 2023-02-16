//
//  OABenefitsOsmContributorsViewController.h
//  OsmAnd
//
//  Created by Skalii on 05.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAAccountSettingDelegate;

@interface OABenefitsOsmContributorsViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OAAccountSettingDelegate> accountDelegate;

@end
