//
//  OAMapSettingsHikingRoutesScreen.mm
//  OsmAnd
//
//  Created by Skalii on 16.08.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsHikingRoutesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "Localization.h"

@implementation OAMapSettingsHikingRoutesScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

    NSArray<NSArray <NSDictionary *> *> *_data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        settingsScreen = EMapSettingsScreenWikipedia;
        vwController = viewController;
        tblView = tableView;
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)commonInit
{

}

- (void)initData
{

}

@end
