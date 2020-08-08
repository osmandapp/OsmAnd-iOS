//
//  OAOsmAccountSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteSettingsBaseViewController.h"

@protocol OAAccontSettingDelegate <NSObject>

- (void) onAccountInformationUpdated;

@end

@interface OAOsmAccountSettingsViewController : OARouteSettingsBaseViewController

@property (nonatomic, weak) id<OAAccontSettingDelegate> delegate;

@end
