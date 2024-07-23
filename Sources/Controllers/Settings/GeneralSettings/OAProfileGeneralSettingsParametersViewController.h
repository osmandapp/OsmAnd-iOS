//
//  OAProfileGeneralSettingsParametersViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"
#import "OAProfileGeneralSettingsViewController.h"

@class OAApplicationMode;

@interface OAProfileGeneralSettingsParametersViewController : OABaseSettingsViewController

- (instancetype) initWithType:(EOAProfileGeneralSettingsParameter)settingsType applicationMode:(OAApplicationMode *)applicationMode;
- (instancetype) initMapOrientationFromMap;

@end
