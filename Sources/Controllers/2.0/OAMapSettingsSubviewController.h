//
//  OAMapSettingsSubviewController.h
//  OsmAnd
//
//  Created by Admin on 11/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef enum
{
    kMapSettingsScreenMapType = 0,
    kMapSettingsScreenDetails,
    kMapSettingsScreenRoutes,
    kMapSettingsScreenHide,
    
    kMapSettingsContourLines,
    kMapSettingsRoadStyle,
}
kMapSettingsScreen;

@interface OAMapSettingsSubviewController : OASuperViewController<UITableViewDelegate, UITableViewDataSource>

-(id)initWithSettingsType:(kMapSettingsScreen)settingsType;

@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property kMapSettingsScreen settingsType;

@end
