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
    EOAProfileGeneralSettingsScreenOrientation,
    EOAProfileGeneralSettingsDisplayPosition,
    EOAProfileGeneralSettingsDrivingRegion,
    EOAProfileGeneralSettingsUnitsOfLenght,
    EOAProfileGeneralSettingsUnitsOfAltitude,
    EOAProfileGeneralSettingsUnitsOfSpeed,
    EOAProfileGeneralSettingsUnitsOfVolume,
    EOAProfileGeneralSettingsUnitsOfTemp,
    EOAProfileGeneralSettingsAngularMeasurmentUnits,
    EOAProfileGeneralSettingsDistanceDuringNavigation,
    EOAProfileGeneralSettingsExternalInputDevices,
    EOAProfileGeneralSettingsScreenCoordsFormat,
    EOAProfileGeneralSettingsAppTheme,
    EOAProfileGeneralSettingsKeepScreenOn
} EOAProfileGeneralSettingsParameter;

@interface OAProfileGeneralSettingsViewController : OABaseSettingsViewController

@end
