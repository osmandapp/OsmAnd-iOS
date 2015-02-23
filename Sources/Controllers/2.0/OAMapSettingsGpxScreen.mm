//
//  OAMapSettingsGpxScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsGpxScreen.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "OAGPXDatabase.h"

@implementation OAMapSettingsGpxScreen {
    NSArray *gpxList;
}


@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        
        settingsScreen = EMapSettingsScreenGpx;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
}

- (void)deinit
{
}

-(void)initData
{
    gpxList = [[[OAGPXDatabase sharedDb] gpxList] sortedArrayUsingComparator:^NSComparisonResult(OAGPX *obj1, OAGPX *obj2) {
        return [[obj1.gpxTitle lowercaseString] compare:[obj2.gpxTitle lowercaseString]];
    }];
}

- (void)setupView
{
    title = @"Tracks";
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return gpxList.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsTableViewCell";
    OASettingsTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
        cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        
        NSArray *visible = settings.mapSettingVisibleGpx;
        OAGPX *gpx = gpxList[indexPath.row];
        
        [cell.textView setText: gpx.gpxTitle];
        [cell.descriptionView setText: @""];
        if ([visible containsObject:gpx.gpxFileName])
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
    
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 5.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *visible = settings.mapSettingVisibleGpx;
    OAGPX *gpx = gpxList[indexPath.row];
    if ([visible containsObject:gpx.gpxFileName]) {
        [settings hideGpx:gpx.gpxFileName];
    } else {
        [settings showGpx:gpx.gpxFileName];
    }
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    
    [tableView reloadData];
}



@end
