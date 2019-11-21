//
//  OAMapSettingsContourLinesScreen.m
//  OsmAnd Maps
//
//  Created by igor on 20.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSettingsContourLinesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "Localization.h"

@implementation OAMapSettingsContourLinesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAMapStyleSettings *styleSettings;
    NSArray *parameters;
    
    NSArray* data;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];

        settingsScreen = EMapSettingsScreenContourLines;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
}

- (void) setupView
{
    styleSettings = [OAMapStyleSettings sharedInstance];
    NSArray *tmpParameters = [styleSettings getAllParameters];
    NSMutableArray *tmpList = [NSMutableArray array];
    
    for (OAMapStyleParameter *p in tmpParameters)
    {
        if ([p.name isEqual: @"contourDensity"] || [p.name isEqual: @"contourWidth"] || [p.name isEqual: @"contourColorScheme"] || [p.name isEqual: @"contourLines"])
            [tmpList addObject: p];
    }
    parameters = [NSArray arrayWithArray:tmpList];
    
    title = OALocalizedString(@"contour_lines");
    [tblView reloadData];
}



- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    OAMapStyleParameter *p = parameters[0]; // iyerin fix hardcode

    if (p.dataType != OABoolean)
        return [OASettingsTableViewCell getHeight:p.title value:[p getValueTitle] cellWidth:tableView.bounds.size.width];
    else
        return [OASwitchTableViewCell getHeight:p.title cellWidth:tableView.bounds.size.width];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (BOOL) contourLinesIsOn
{
    OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
    return [parameter.value isEqual:@"disabled"] ? false : true;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self contourLinesIsOn])
        return parameters.count + 1;
    return 1;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row > 0)
    {
        OAMapStyleParameter *p = parameters[indexPath.row - 1];
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:p.title];
            if ([p.title isEqualToString:@"Show contour lines"])
                [cell.textView setText:OALocalizedString(@"display_starting_at_zoom_level")];
            [cell.descriptionView setText:[p getValueTitle]];
            if ([[p getValueTitle] isEqual:@""])
            {
                [cell.descriptionView setText:OALocalizedString(@"default_13")];
            }
        }
        
        return cell;
    }
    else
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSString *cellText = [self contourLinesIsOn] ? @"Enabled" : @"Disabled";
            [cell.textView setText:cellText];
            [cell.switchView setOn:[self contourLinesIsOn]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }

}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        OAMapStyleParameter *p = parameters[indexPath.row - 1];
        if (p.dataType != OABoolean)
        {
            OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];

            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];

            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
        parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [styleSettings save:parameter];
    }
    [tblView reloadData];
}

@end
