//
//  OAMapSettingsParameterScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsParameterScreen.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"

@implementation OAMapSettingsParameterScreen {
    
    OAMapStyleSettings *styleSettings;
    OAMapStyleParameter *parameter;
    
}


@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource, parameterName;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        
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

- (void)setupView
{
    styleSettings = [OAMapStyleSettings sharedInstance];
    parameter = [styleSettings getParameter:parameterName];
    title = parameter.title;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return parameter.possibleValues.count;
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
        CGRect f = cell.textView.frame;
        cell.textView.frame = CGRectMake(f.origin.x, f.origin.y, cell.bounds.size.width - f.origin.x * 2.0 - 30.0, f.size.height);
        [cell.descriptionView removeFromSuperview];
    }
    
    if (cell) {
        
        OAMapStyleParameterValue *value = parameter.possibleValues[indexPath.row];
        
        [cell.textView setText: value.title];
        
        if ([parameter.value isEqualToString:value.name])
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    
    return cell;
    
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapStyleParameterValue *value = parameter.possibleValues[indexPath.row];
    parameter.value = value.name;
    [styleSettings save:parameter];
    
    [tableView reloadData];
}



@end
