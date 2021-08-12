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
    EOAProfileGeneralSettingsMapOrientation = 0,
    EOAProfileGeneralSettingsDrivingRegion,
    EOAProfileGeneralSettingsUnitsOfLenght,
    EOAProfileGeneralSettingsUnitsOfSpeed,
    EOAProfileGeneralSettingsAngularMeasurmentUnits,
    EOAProfileGeneralSettingsExternalInputDevices,
    EOAProfileGeneralSettingsScreenCoordsFormat,
} EOAProfileGeneralSettingsParameter;

@interface OAProfileGeneralSettingsViewController : OABaseSettingsViewController

@end
