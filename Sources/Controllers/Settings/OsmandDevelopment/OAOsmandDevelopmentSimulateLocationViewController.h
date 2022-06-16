//
//  OAOsmandDevelopmentSimulateLocationViewController.h
//  OsmAnd
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@protocol OAOsmandDevelopmentSimulateLocationDelegate <NSObject>

- (void) onSimulateLocationInformationUpdated;

@end


@interface OAOsmandDevelopmentSimulateLocationViewController : OABaseSettingsViewController

@property (nonatomic, weak) id<OAOsmandDevelopmentSimulateLocationDelegate> simulateLocationDelegate;

@end
