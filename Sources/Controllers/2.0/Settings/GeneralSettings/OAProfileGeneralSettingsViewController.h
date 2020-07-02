//
//  OAProfileGeneralSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 01.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

typedef enum
{
    kProfileGeneralSettingsMapOrientation = 0,
    kProfileGeneralSettingsDrivingRegion,
    kProfileGeneralSettingsUnitsOfLenght,
    kProfileGeneralSettingsUnitsOfSpeed,
    kProfileGeneralSettingsAngularMeasurmentUnits,
    kProfileGeneralSettingsExternalInputDevices,
    kProfileGeneralSettingsScreenCoordsFormat,
} kProfileGeneralSettingsParameter;

@interface OAProfileGeneralSettingsViewController : OABaseSettingsViewController

@property (nonatomic, readonly) kProfileGeneralSettingsParameter settingsType;

@end
