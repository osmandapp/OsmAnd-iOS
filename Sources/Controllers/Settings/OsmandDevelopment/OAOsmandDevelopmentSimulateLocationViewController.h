//
//  OAOsmandDevelopmentSimulateLocationViewController.h
//  OsmAnd
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAOsmandDevelopmentSimulateLocationDelegate <NSObject>

- (void) onSimulateLocationInformationUpdated;

@end

@interface OAOsmandDevelopmentSimulateLocationViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OAOsmandDevelopmentSimulateLocationDelegate> simulateLocationDelegate;

@end
