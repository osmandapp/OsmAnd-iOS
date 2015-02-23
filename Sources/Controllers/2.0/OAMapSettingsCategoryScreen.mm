//
//  OAMapSettingsCategoryScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsCategoryScreen.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

@implementation OAMapSettingsCategoryScreen {
    
    OAMapStyleSettings *styleSettings;
    NSArray *parameters;
    
    NSArray* data;
}


@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource, categoryName;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        
        categoryName = param;

        settingsScreen = EMapSettingsScreenCategory;
        
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
    styleSettings = [[OAMapStyleSettings alloc] init];
    parameters = [styleSettings getParameters:categoryName];
    title = [styleSettings getCategoryTitle:categoryName];
    
    [tblView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return parameters.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapStyleParameter *p = parameters[indexPath.row];
    
    if (p.dataType != OABoolean) {
        
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText: p.title];
            [cell.descriptionView setText: p.value];
        }
        
        return cell;
        
    } else {
        
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText: p.title];
            [cell.switchView setOn: [p.value isEqualToString:@"true"]];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.row;
        }
        
        return cell;
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 5.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapStyleParameter *p = parameters[indexPath.row];
    OAMapSettingsViewController *mapSourcesViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];
    [vwController.navigationController pushViewController:mapSourcesViewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) mapSettingSwitchChanged:(id)sender
{
     UISwitch *switchView = (UISwitch*)sender;
     if (switchView) {
         OAMapStyleParameter *p = parameters[switchView.tag];
         if (p) {
             p.value = switchView.isOn ? @"true" : @"false";
             [styleSettings save:p];
         }
     }
}


@end
