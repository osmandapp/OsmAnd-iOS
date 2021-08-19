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

static const NSInteger visibilitySection = 0;
static const NSInteger colorsSection = 1;

typedef enum
{
    ERoutesSettingCycle = 0,
    ERoutesSettingHiking,
    ERoutesSettingTravel

} ERoutesSettingType;

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

        if ([param isEqualToString:SHOW_CYCLE_ROUTES_ATTR])
        {
            _routesSettingType = ERoutesSettingCycle;
            settingsScreen = EMapSettingsScreenCycleRoutes;
            _routesEnabled = _routesParameter.storedValue.length > 0 && [_routesParameter.storedValue isEqualToString:@"true"];
        }
        else if ([param isEqualToString:HIKING_ROUTES_OSMC_ATTR])
        {
            _routesSettingType = ERoutesSettingHiking;
            settingsScreen = EMapSettingsScreenHikingRoutes;
            _routesEnabled = _routesParameter.storedValue.length > 0 && ![_routesParameter.storedValue isEqualToString:@"disabled"];
        }
        else
        {
            _routesSettingType = ERoutesSettingTravel;
            settingsScreen = EMapSettingsScreenTravelRoutes;
            _routesEnabled = _routesParameter.storedValue.length > 0;
        }

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
    NSMutableArray *dataArr = [@[
            @[
                    @{@"type": [OADividerCell getCellIdentifier]},
                    @{@"type": [OASettingSwitchCell getCellIdentifier]},
                    @{@"type": [OADividerCell getCellIdentifier]}
            ]
    ] mutableCopy];

    NSMutableArray *colorsArr = [@[@{@"type": [OADividerCell getCellIdentifier]}] mutableCopy];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        [colorsArr addObject:@{
                @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                @"value": @"false",
                @"title": OALocalizedString(@"gpx_route")
        }];
        [colorsArr addObject:@{
                @"type": [OASettingsTitleTableViewCell getCellIdentifier],
                @"value": @"true",
                @"title": OALocalizedString(@"rendering_value_walkingRoutesOSMCNodes_name")
        }];
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
            }
        }
    }
    [colorsArr addObject:@{@"type": [OADividerCell getCellIdentifier]}];
    [dataArr addObject:colorsArr];

    _data = [NSArray arrayWithArray:dataArr];
}

- (void)setupView
{
    title = _routesParameter.title;

    [tblView.tableFooterView removeFromSuperview];
    tblView.tableFooterView = nil;
    [tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    tblView.rowHeight = UITableViewAutomaticDimension;
    tblView.estimatedRowHeight = kEstimatedRowHeight;
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

- (NSString *)getTextForFooter:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
        return @"";

    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
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
    if (section != visibilitySection && !_routesEnabled)
        return 0;

    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.dividerHight = 0.5;
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
            cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
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
            cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
        }
        if (cell)
        {
            BOOL selected;
            if (_routesSettingType == ERoutesSettingCycle)
            {
                OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
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
    if ([[self getItem:indexPath][@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else
        return UITableViewAutomaticDimension;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != visibilitySection ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != visibilitySection)
        [self onItemClicked:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == colorsSection && _routesEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
        return 0.01;

    return 56.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
        return @"";

    return OALocalizedString(@"routes_color_by_type");
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getFooterHeightForSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
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
                OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
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
        [tblView reloadSections:[NSIndexSet indexSetWithIndex:colorsSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
    }
}

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSString *value = [self getItem:indexPath][@"value"];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
        if (![cycleNode.value isEqualToString:value])
        {
            cycleNode.value = value;
            [_styleSettings save:cycleNode];
            [tblView reloadSections:[NSIndexSet indexSetWithIndex:colorsSection] withRowAnimation:UITableViewRowAnimationAutomatic];
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
            [tblView reloadSections:[NSIndexSet indexSetWithIndex:colorsSection] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

@end
