//
//  OAMapSettingsViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OACommonTypes.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAGPXDocumentPrimitives.h"

typedef enum
{
    EMapSettingsScreenUndefined = -1,
    EMapSettingsScreenMain = 0,
    EMapSettingsScreenGpx,
    EMapSettingsScreenMapType,
    EMapSettingsScreenCategory,
    EMapSettingsScreenParameter,
    EMapSettingsScreenSetting,
    
} EMapSettingsScreen;


@interface OAMapSettingsViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UIScrollView *mapTypeScrollView;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonView;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonCar;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonWalk;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonBike;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL goToMap;
@property (nonatomic, assign) OAGpxBounds goToBounds;

-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen;
-(id)initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param;

@end
