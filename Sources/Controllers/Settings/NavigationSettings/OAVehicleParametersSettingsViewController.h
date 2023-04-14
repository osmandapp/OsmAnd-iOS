//
//  OAVehicleParametersSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@class OAApplcicationMode;

@interface OAVehicleParametersSettingsViewController : OABaseSettingsViewController

- (instancetype)initWithApplicationMode:(OAApplicationMode *)am vehicleParameter:(NSDictionary *)vp;

@end
