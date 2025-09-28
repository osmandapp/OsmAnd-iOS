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
#import "OASimpleTableViewCell.h"
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
    if ([parameterName isEqualToString:CONTOUR_LINES])
        return parameter.possibleValues.count - 1; //without "Disabled"
    return parameter.possibleValues.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OASimpleTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
    }
    
    if (cell)
    {
        OAMapStyleParameterValue *value = parameter.possibleValues[indexPath.row];
        [cell.titleLabel setText:value.title.length ? value.title : parameter.defaultValue.length ? parameter.defaultValue : value.name];
        BOOL selected = [parameter.value isEqualToString:value.name] || (value.name.length == 0 && parameter.defaultValue.length && [parameter.value isEqualToString:parameter.defaultValue]);
        cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
    parameter.value = value.name.length ? value.name : parameter.defaultValue;
    [styleSettings save:parameter];
    
    if ([parameterName isEqualToString:CONTOUR_LINES])
        [[OAAppSettings sharedManager].contourLinesZoom set:parameter.value];
    
    [tableView reloadData];
}

@end
