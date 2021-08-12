//
//  OAMapSettingsParameterScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsParameterScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTitleTableViewCell.h"
#import "Localization.h"

@implementation OAMapSettingsParameterScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAMapStyleSettings *styleSettings;
    OAMapStyleParameter *parameter;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource, parameterName;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        parameterName = param;
        
        settingsScreen = EMapSettingsScreenParameter;
        
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
}

- (void) setupView
{
    styleSettings = [OAMapStyleSettings sharedInstance];
    parameter = [styleSettings getParameter:parameterName];
    title = parameter.title;
    self.tblView.rowHeight = UITableViewAutomaticDimension;
    self.tblView.estimatedRowHeight = kEstimatedRowHeight;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([parameterName isEqualToString:@"contourLines"])
        return parameter.possibleValues.count - 1; //without "Disabled"
    return parameter.possibleValues.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OASettingsTitleTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OAMapStyleParameterValue *value = parameter.possibleValues[indexPath.row];
        [cell.textView setText:value.title];
        if ([parameter.value isEqualToString:value.name])
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapStyleParameterValue *value = parameter.possibleValues[indexPath.row];
    parameter.value = value.name;
    [styleSettings save:parameter];
    
    if ([parameterName isEqualToString:@"contourLines"])
        [[OAAppSettings sharedManager].contourLinesZoom set:value.name];
    
    [tableView reloadData];
}

@end
