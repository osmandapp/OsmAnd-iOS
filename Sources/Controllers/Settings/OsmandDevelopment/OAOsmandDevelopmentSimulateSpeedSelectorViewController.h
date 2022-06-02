//
//  OAOsmandDevelopmentSimulateSpeedSelectorViewController.h
//  OsmAnd
//
//  Created by nnngrach on 02.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@protocol OAOsmandDevelopmentSimulateSpeedSelectorDelegate <NSObject>

- (void) onSpeedSelectorInformationUpdated:(NSInteger)selectedSpeedModeIndex;

@end


@interface OAOsmandDevelopmentSimulateSpeedSelectorViewController : OABaseSettingsViewController

@property (nonatomic, weak) id<OAOsmandDevelopmentSimulateSpeedSelectorDelegate> speedSelectorDelegate;

@end
