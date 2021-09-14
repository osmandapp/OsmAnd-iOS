//
//  OAMapSettingsRoutesScreen.mm
//  OsmAnd
//
//  Created by Skalii on 16.08.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsRoutesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OADividerCell.h"
#import "OASettingSwitchCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAMapStyleSettings.h"

typedef NS_ENUM(NSInteger, EOAMapSettingsRoutesSection)
{
    EOAMapSettingsRoutesSectionVisibility = 0,
    EOAMapSettingsRoutesSectionColors
};

typedef NS_ENUM(NSInteger, ERoutesSettingType)
{
    ERoutesSettingCycle = 0,
    ERoutesSettingHiking,
    ERoutesSettingTravel

};

@implementation OAMapSettingsRoutesScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_routesParameter;
    ERoutesSettingType _routesSettingType;

    NSArray<NSArray <NSDictionary *> *> *_data;
    BOOL _routesEnabled;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _styleSettings = [OAMapStyleSettings sharedInstance];
        _routesParameter = [_styleSettings getParameter:param];
        settingsScreen = EMapSettingsScreenRoutes;

        if ([param isEqualToString:kShowCycleRoutesAttr])
        {
            _routesSettingType = ERoutesSettingCycle;
            _routesEnabled = _routesParameter.storedValue.length > 0 && [_routesParameter.storedValue isEqualToString:@"true"];
        }
        else if ([param isEqualToString:kHikingRoutesOsmcAttr])
        {
            _routesSettingType = ERoutesSettingHiking;
            _routesEnabled = _routesParameter.storedValue.length > 0 && ![_routesParameter.storedValue isEqualToString:@"disabled"];
        }
        else
        {
            _routesSettingType = ERoutesSettingTravel;
            _routesEnabled = _routesParameter.storedValue.length > 0;
        }

        vwController = viewController;
        tblView = tableView;
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [self initData];
    }
    return self;
}

- (void)initData
{
    NSMutableArray *dataArr = [NSMutableArray new];

    [dataArr addObject:@[
                    @{@"type": [OADividerCell getCellIdentifier]},
                    @{@"type": [OASettingSwitchCell getCellIdentifier]},
                    @{@"type": [OADividerCell getCellIdentifier]}
    ]];

    NSMutableArray *colorsArr = [NSMutableArray new];
    [colorsArr addObject:@{@"type": [OADividerCell getCellIdentifier]}];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        [colorsArr addObject:@{
                @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                @"value": @"false",
                @"title": OALocalizedString(@"gpx_route")
        }];
        [colorsArr addObject:@{@"type": [OADividerCell getCellIdentifier]}];
        [colorsArr addObject:@{
                @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                @"value": @"true",
                @"title": OALocalizedString(@"rendering_value_walkingRoutesOSMCNodes_name")
        }];
        [colorsArr addObject:@{@"type": [OADividerCell getCellIdentifier]}];
    }
    else
    {
        for (OAMapStyleParameterValue *value in _routesParameter.possibleValuesUnsorted)
        {
            if (value.name.length != 0)
            {
                [colorsArr addObject:@{
                        @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                        @"value": value.name,
                        @"title": value.title
                }];
                [colorsArr addObject:@{@"type": [OADividerCell getCellIdentifier]}];
            }
        }
    }
    [dataArr addObject:colorsArr];

    _data = dataArr;
}

- (void)setupView
{
    title = _routesParameter.title;

    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [tblView.tableFooterView removeFromSuperview];
    tblView.tableFooterView = nil;
    [tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getRenderingStringPropertyDescription:(NSString *)propertyValue
{
    if (!propertyValue)
        return @"";

    NSString *propertyValueReplaced = [propertyValue stringByReplacingOccurrencesOfString:@"\\s+" withString:@"_"];
    NSString *value = OALocalizedString([NSString stringWithFormat:@"rendering_value_%@_description", propertyValueReplaced]);
    return value ? value : propertyValue;
}

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else
        return estimated ? 48. : UITableViewAutomaticDimension;
}

- (NSString *)getTextForFooter:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return @"";

    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:kCycleNodeNetworkRoutesAttr];
        return [cycleNode.value isEqualToString:@"true"] ? [self getRenderingStringPropertyDescription:@"walkingRoutesOSMCNodes"] : OALocalizedString(@"walking_route_osmc_description");
    }

    return [self getRenderingStringPropertyDescription:_routesParameter.value];
}

- (CGFloat)getFooterHeightForSection:(NSInteger)section
{
    return [OATableViewCustomFooterView getHeight:[self getTextForFooter:section] width:tblView.frame.size.width];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section != EOAMapSettingsRoutesSectionVisibility && !_routesEnabled)
        return 0;

    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
            cell.dividerHight = 0.5;
        }
        if (cell)
        {
            CGFloat leftInset = indexPath.row == 0 || indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 ? 0. : 20.;
            cell.dividerInsets = UIEdgeInsetsMake(0., leftInset, 0., 0.);
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.text = _routesEnabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = _routesEnabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [UIImage templateImageNamed:imgName];
            cell.imgView.tintColor = _routesEnabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);

            [cell.switchView setOn:_routesEnabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *) nib[0];
        }
        if (cell)
        {
            BOOL selected;
            if (_routesSettingType == ERoutesSettingCycle)
            {
                OAMapStyleParameter *cycleNode = [_styleSettings getParameter:kCycleNodeNetworkRoutesAttr];
                selected = [cycleNode.value isEqualToString:item[@"value"]];
            }
            else
            {
                selected = [_routesParameter.value isEqualToString:item[@"value"]];
            }

            cell.textView.text = item[@"title"];
            [cell.iconView setImage:selected ? [UIImage imageNamed:@"menu_cell_selected"] : nil];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    return [item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
        [self onItemClicked:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == EOAMapSettingsRoutesSectionColors && _routesEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return 0.01;

    return 56.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return @"";

    return OALocalizedString(@"routes_color_by_type");
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getFooterHeightForSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return nil;

    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    NSString *text = [self getTextForFooter:section];
    vw.label.text = text;
    return vw;
}

#pragma mark - Selectors

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        [tblView beginUpdates];
        UISwitch *sw = (UISwitch *) sender;
        _routesEnabled = sw.on;

        if (_routesEnabled)
        {
            if (_routesSettingType == ERoutesSettingCycle)
                _routesParameter.value = @"true";
            else if (_routesSettingType == ERoutesSettingHiking)
                _routesParameter.value = @"walkingRoutesOSMC";
        }
        else
        {
            if (_routesSettingType == ERoutesSettingCycle)
            {
                _routesParameter.value = @"false";
                OAMapStyleParameter *cycleNode = [_styleSettings getParameter:kCycleNodeNetworkRoutesAttr];
                cycleNode.value = @"false";
                [_styleSettings save:cycleNode];
            }
            else if (_routesSettingType == ERoutesSettingHiking)
            {
                _routesParameter.value = @"disabled";
            }
            else if (_routesSettingType == ERoutesSettingTravel)
            {
            }
        }
        [_styleSettings save:_routesParameter];

        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsRoutesSectionColors] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
    }
}

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSString *value = [self getItem:indexPath][@"value"];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:kCycleNodeNetworkRoutesAttr];
        if (![cycleNode.value isEqualToString:value])
        {
            cycleNode.value = value;
            [_styleSettings save:cycleNode];
        }
        if (![_routesParameter.value isEqualToString:@"true"])
        {
            _routesParameter.value = @"true";
            [_styleSettings save:_routesParameter];
        }
    }
    else
    {
        if (![_routesParameter.value isEqualToString:value])
        {
            _routesParameter.value = value;
            [_styleSettings save:_routesParameter];
        }
    }
    [UIView setAnimationsEnabled:NO];
    [tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsRoutesSectionColors] withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
