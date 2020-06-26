//
//  OAMapSettingsCategoryScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsCategoryScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"

@implementation OAMapSettingsCategoryScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAMapStyleSettings *styleSettings;
    NSArray *parameters;
    NSArray* data;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource, categoryName;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        categoryName = param;

        settingsScreen = EMapSettingsScreenCategory;
        
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
    if ([categoryName isEqual: @"details"])
    {
        NSMutableArray *withoutContoursLines;
        withoutContoursLines = [[styleSettings getParameters:categoryName] mutableCopy];
        int i = 0;
        for (OAMapStyleParameter *p in withoutContoursLines)
        {
            if ([p.name  isEqual: @"contourLines"])
                break;
            i++;
        }
        [withoutContoursLines removeObjectAtIndex:(i)];
        parameters = [NSArray arrayWithArray:withoutContoursLines];
    }
    else
    {
        parameters = [styleSettings getParameters:categoryName];
    }
    [tblView reloadData];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    OAMapStyleParameter *p = parameters[indexPath.row];
    
    if (p.dataType != OABoolean)
        return [OASettingsTableViewCell getHeight:p.title value:[p getValueTitle] cellWidth:tableView.bounds.size.width];
    else
        return UITableViewAutomaticDimension;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return parameters.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapStyleParameter *p = parameters[indexPath.row];
    if (p.dataType != OABoolean)
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
            [cell.textView setText:p.title];
            [cell.descriptionView setText:[p getValueTitle]];
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
            [cell.textView setText:p.title];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.row;
            
            if ([categoryName isEqual:@"transport"])
                [cell.switchView setOn:[self getVisibilityForStyleParameter:p.name]];
            else
                [cell.switchView setOn:[p.value isEqualToString:@"true"]];
        }
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kEstimatedRowHeight;
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
    OAMapStyleParameter *p = parameters[indexPath.row];
    if (p.dataType != OABoolean)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];
        
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];

        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (!switchView)
        return;
    
    OAMapStyleParameter *p = parameters[switchView.tag];
    if (!p)
        return;
    
    if ([categoryName isEqual:@"transport"])
        [self updateWithProfileSettingsStyleParameter:p visibiliry:switchView.isOn];
    else
        [self updateDirectlyStyleParameter:p visibiliry:switchView.isOn];
}


- (void) updateDirectlyStyleParameter:(OAMapStyleParameter *)parameter visibiliry:(BOOL)isVisible
{
    dispatch_async(dispatch_get_main_queue(), ^{
        parameter.value = isVisible ? @"true" : @"false";
        [styleSettings save:parameter];
        [[_app mapSettingsChangeObservable] notifyEvent];
    });
}

- (void) updateWithProfileSettingsStyleParameter:(OAMapStyleParameter *)parameter visibiliry:(BOOL)isVisible
{
    if (isVisible)
        [_settings.transportLayersVisible addUnic:parameter.name];
    else
        [_settings.transportLayersVisible remove:parameter.name];
    
    if (_settings.mapSettingShowPublicTransport)
        [self updateDirectlyStyleParameter:parameter visibiliry:isVisible];
}

- (BOOL) getVisibilityForStyleParameter:(NSString*)parameterName
{
    return [_settings.transportLayersVisible contain:parameterName];
}

@end
