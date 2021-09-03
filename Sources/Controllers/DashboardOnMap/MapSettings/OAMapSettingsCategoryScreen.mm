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
#import "Localization.h"

@implementation OAMapSettingsCategoryScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAMapStyleSettings *_styleSettings;
    NSArray<OAMapStyleParameter *> *_parameters;

    BOOL _isDetailsCategory;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource, categoryName;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _styleSettings = [OAMapStyleSettings sharedInstance];

        categoryName = param;
        _isDetailsCategory = [categoryName isEqual:@"details"];

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
    if (_isDetailsCategory)
    {
        NSMutableArray<OAMapStyleParameter *> *withoutContoursLines;
        withoutContoursLines = [[_styleSettings getParameters:categoryName] mutableCopy];
        int i = 0;
        for (OAMapStyleParameter *p in withoutContoursLines)
        {
            if ([p.name isEqual:@"contourLines"])
                break;
            i++;
        }
        [withoutContoursLines removeObjectAtIndex:(i)];
        _parameters = [NSArray arrayWithArray:withoutContoursLines];
    }
    else
    {
        _parameters = [_styleSettings getParameters:categoryName];
    }
    [tblView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _isDetailsCategory ? _parameters.count + 1 : _parameters.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL isPointLabelsRow = _isDetailsCategory && indexPath.row == 0;
    OAMapStyleParameter *p = !isPointLabelsRow ? _parameters[_isDetailsCategory ? indexPath.row - 1 : indexPath.row] : nil;
    if (isPointLabelsRow || p.dataType == OABoolean)
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
        }
        if (cell)
        {
            [cell.textView setText:isPointLabelsRow ? OALocalizedString(@"layer_amenity_label") : p.title];
            [cell.switchView setOn:isPointLabelsRow ? [_settings.mapSettingShowPoiLabel get] : [p.storedValue isEqualToString:@"true"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.row;
        }
        return cell;
    }
    else
    {
        OASettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *) nib[0];
        }
        if (cell)
        {
            [cell.textView setText:p.title];
            [cell.descriptionView setText:[p getValueTitle]];
        }
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kEstimatedRowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    OAMapStyleParameter *p = _parameters[indexPath.row];
    if (p.dataType != OABoolean)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
}

#pragma mark - Switch

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        if (_isDetailsCategory && switchView.tag == 0)
        {
            [_settings setShowPoiLabel:switchView.isOn];
        }
        else
        {
            OAMapStyleParameter *p = _parameters[_isDetailsCategory ? switchView.tag - 1 : switchView.tag];
            if (p)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    p.value = switchView.isOn ? @"true" : @"false";
                    [_styleSettings save:p];
                });
            }
        }
    }
}

@end
