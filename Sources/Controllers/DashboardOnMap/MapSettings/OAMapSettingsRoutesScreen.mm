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
#import "OAMapPanelViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OASwitchTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OASizes.h"
#import "OAMapStyleSettings.h"
#import "GeneratedAssetSymbols.h"

typedef NS_ENUM(NSInteger, EOAMapSettingsRoutesSection)
{
    EOAMapSettingsRoutesSectionVisibility = 0,
    EOAMapSettingsRoutesSectionValues
};

typedef NS_ENUM(NSInteger, ERoutesSettingType)
{
    ERoutesSettingCycle = 0,
    ERoutesSettingMountain,
    ERoutesSettingHiking,
    ERoutesSettingTravel,
    ERoutesSettingDifficultyClassification
};

@implementation OAMapSettingsRoutesScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_routesParameter;
    ERoutesSettingType _routesSettingType;
    OAAppSettings *_settings;

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
        tblView = tableView;
        settingsScreen = EMapSettingsScreenRoutes;
        
        _routesParameter = [_styleSettings getParameter:param];
        if ([param isEqualToString:SHOW_CYCLE_ROUTES_ATTR])
        {
            _routesSettingType = ERoutesSettingCycle;
            _routesEnabled = _routesParameter.storedValue.length > 0 && [_routesParameter.storedValue isEqualToString:@"true"];
        }
        else if ([param isEqualToString:SHOW_MTB_ROUTES])
        {
            _routesSettingType = ERoutesSettingMountain;
            _routesEnabled = _routesParameter.storedValue.length > 0 && [_routesParameter.storedValue isEqualToString:@"true"];
        }
        else if ([param isEqualToString:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES])
        {
            _routesParameter.title = OALocalizedString(@"rendering_attr_alpineHiking_name");
            _routesSettingType = ERoutesSettingDifficultyClassification;
            _routesEnabled = [[_styleSettings getParameter:ALPINE_HIKING_ATTR].value isEqualToString:@"true"];
        }
        else if ([param isEqualToString:HIKING_ROUTES_OSMC_ATTR])
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
        
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        _settings = [OAAppSettings sharedManager];
        [self initData];
    }
    return self;
}

- (void)initData
{
    NSMutableArray *dataArr = [NSMutableArray new];
    
    [dataArr addObject:@[@{@"type": [OASwitchTableViewCell getCellIdentifier]}]];
    
    NSMutableArray *valuesArr = [NSMutableArray new];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        [valuesArr addObject:@{
            @"type": [OARightIconTableViewCell getCellIdentifier],
            @"value": @"false",
            @"title": OALocalizedString(@"layer_route")
        }];
        [valuesArr addObject:@{
            @"type": [OARightIconTableViewCell getCellIdentifier],
            @"value": @"true",
            @"title": OALocalizedString(@"rendering_value_walkingRoutesOSMCNodes_name")
        }];
    }
    else if (_routesSettingType == ERoutesSettingMountain)
    {
        OAMapStyleParameter *mtbScale = [_styleSettings getParameter:SHOW_MTB_SCALE];
        if (mtbScale)
        {
            [valuesArr addObject:@{
                @"type": [OARightIconTableViewCell getCellIdentifier],
                @"value": mtbScale.value,
                @"title": mtbScale.title
            }];
        }
        OAMapStyleParameter *imbaTrails = [_styleSettings getParameter:SHOW_MTB_SCALE_IMBA_TRAILS];
        if (imbaTrails)
        {
            [valuesArr addObject:@{
                @"type": [OARightIconTableViewCell getCellIdentifier],
                @"value": imbaTrails.value,
                @"title": imbaTrails.title
            }];
        }
    }
    else if (_routesSettingType == ERoutesSettingDifficultyClassification)
    {
        OAMapStyleParameter *alpineHikingScaleRoutes = [_styleSettings getParameter:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES];
        if (alpineHikingScaleRoutes)
        {
            for (OAMapStyleParameterValue *value in alpineHikingScaleRoutes.possibleValuesUnsorted)
            {
                if (value.name.length > 0)
                {
                    [valuesArr addObject:@{
                        @"type": [OARightIconTableViewCell getCellIdentifier],
                        @"value": value.name,
                        @"title": [OALocalizedString(([NSString stringWithFormat:@"rendering_value_%@_name", value.name])) upperCase],
                        @"description": [self getRenderingStringPropertyDescription:value.name],
                    }];
                }
            }
        }
    }
    else if (_routesSettingType == ERoutesSettingHiking)
    {
        for (OAMapStyleParameterValue *value in _routesParameter.possibleValuesUnsorted)
        {
            if (value.name.length != 0)
            {
                [valuesArr addObject:@{
                    @"type": [OARightIconTableViewCell getCellIdentifier],
                    @"value": value.name,
                    @"title": value.title
                }];
            }
        }
    }
    [dataArr addObject:valuesArr];
    
    _data = dataArr;
}

- (void)setupView
{
    title = _routesParameter.title;
    tblView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
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
    
    NSString *key = [NSString stringWithFormat:@"rendering_value_%@_description", propertyValueReplaced];
    NSString *value = OALocalizedString(key);
    
    if (!value || [value isEqualToString:key]) {
        key = [NSString stringWithFormat:@"rendering_attr_%@_description", propertyValueReplaced];
        value = OALocalizedString(key);
    }
    
    if (!value || [value isEqualToString:key]) {
        value = propertyValue;
    }
    
    return value;
}

- (NSString *)getTextForFooter:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return @"";

    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
        return cycleNode && [cycleNode.value isEqualToString:@"true"] ? [self getRenderingStringPropertyDescription:@"walkingRoutesOSMCNodes"] : OALocalizedString(@"walking_route_osmc_description");
    }
    else if (_routesSettingType == ERoutesSettingMountain)
    {
        OAMapStyleParameter *imbaTrails = [_styleSettings getParameter:SHOW_MTB_SCALE_IMBA_TRAILS];
        return imbaTrails && [imbaTrails.value isEqualToString:@"true"] ? [self getRenderingStringPropertyDescription:imbaTrails.name] : @"";
    }
    else if (_routesSettingType == ERoutesSettingDifficultyClassification)
    {
        OAMapStyleParameter *alpineHikingAttr = [_styleSettings getParameter:SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES];
        return alpineHikingAttr ? [self getRenderingStringPropertyDescription:alpineHikingAttr.name] : @"";
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
    if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            BOOL enabled = _routesEnabled;
            BOOL isMountain = _routesSettingType == ERoutesSettingMountain;
            BOOL isDifficultyClassification = _routesSettingType == ERoutesSettingDifficultyClassification;
            if (isDifficultyClassification)
            {
                cell.titleLabel.text = title;
            }
            else
            {
                [cell descriptionVisibility:NO];
                cell.titleLabel.text = enabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            }
            
            NSString *imgName = enabled ? @"ic_custom_show" : @"ic_custom_hide";
            if (isMountain)
            {
                imgName = @"ic_action_bicycle_dark";
            }
            else if (isDifficultyClassification)
            {
                imgName = @"ic_action_trekking_dark";
            }
            
            cell.leftIconView.image = [UIImage templateImageNamed:imgName];
            cell.leftIconView.tintColor = enabled ? isMountain || isDifficultyClassification ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];

            [cell.switchView setOn:enabled];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            [cell rightIconVisibility:NO];
            
        }
        if (cell)
        {
            BOOL selected;
            if (_routesSettingType == ERoutesSettingCycle)
            {
                OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
                selected = cycleNode && [cycleNode.value isEqualToString:item[@"value"]];
            }
            else if (_routesSettingType == ERoutesSettingMountain)
            {
                selected = [item[@"value"] isEqualToString:@"true"];
            }
            else
            {
                selected = [_routesParameter.value isEqualToString:item[@"value"]];
            }

            cell.titleLabel.text = item[@"title"];
            if (item[@"description"])
            {
                [cell descriptionVisibility:YES];
                cell.descriptionLabel.text = item[@"description"];
            }
            if (selected)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }

        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    return [item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
        [self onItemClicked:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == EOAMapSettingsRoutesSectionValues && _routesEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility || _routesSettingType == ERoutesSettingDifficultyClassification)
        return @"";

    return _routesSettingType == ERoutesSettingMountain ? OALocalizedString(@"mtb_segment_classification") : OALocalizedString(@"routes_color_by_type");
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == EOAMapSettingsRoutesSectionVisibility)
        return 0.01;
    if (_routesSettingType == ERoutesSettingDifficultyClassification)
        return 30.0;
    
    NSString *header = _routesSettingType == ERoutesSettingMountain ? OALocalizedString(@"mtb_segment_classification") : OALocalizedString(@"routes_color_by_type");
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    CGFloat headerHeight = [OAUtilities calculateTextBounds:header
                                                      width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                       font:font].height + kPaddingOnSideOfHeaderWithText;
    return headerHeight;
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
        _routesEnabled = sw.on;

        if (_routesSettingType == ERoutesSettingMountain)
        {
            NSString *mountainBikeRoutesParameter = [_settings.mountainBikeRoutesParameter get];
            _routesParameter.value = _routesEnabled ? @"true" : @"false";
            OAMapStyleParameter *mtbScale = [_styleSettings getParameter:SHOW_MTB_SCALE];
            if (mtbScale)
            {
                mtbScale.value = _routesEnabled && [mountainBikeRoutesParameter isEqualToString:mtbScale.name] ? @"true" : @"false";
                [_styleSettings save:mtbScale];
            }
            OAMapStyleParameter *mtbScaleUphill = [_styleSettings getParameter:SHOW_MTB_SCALE_UPHILL];
            if (mtbScaleUphill)
            {
                mtbScaleUphill.value = mtbScale ? mtbScale.value : @"false";
                [_styleSettings save:mtbScaleUphill];
            }
            OAMapStyleParameter *imbaTrails = [_styleSettings getParameter:SHOW_MTB_SCALE_IMBA_TRAILS];
            if (imbaTrails)
            {
                imbaTrails.value = _routesEnabled && [mountainBikeRoutesParameter isEqualToString:imbaTrails.name] ? @"true" : @"false";
                [_styleSettings save:imbaTrails];
            }
            [self initData];
        }
        else if (_routesSettingType == ERoutesSettingDifficultyClassification)
        {
            OAMapStyleParameter *attr = [_styleSettings getParameter:ALPINE_HIKING_ATTR];
            if (attr)
            {
                attr.value = _routesEnabled ? @"true" : @"false";
                [_styleSettings save:attr];
            }
        }
        else if (_routesEnabled)
        {
            if (_routesSettingType == ERoutesSettingCycle)
            {
                _routesParameter.value = @"true";
                cycleNode.value = [_settings.cycleRoutesParameter get];
                [_styleSettings save:cycleNode];
            }
            else if (_routesSettingType == ERoutesSettingHiking)
                _routesParameter.value = [_settings.hikingRoutesParameter get];
        }
        else
        {
            if (_routesSettingType == ERoutesSettingCycle)
            {
                _routesParameter.value = @"false";
                if (cycleNode)
                {
                    cycleNode.value = @"false";
                    [_styleSettings save:cycleNode];
                }
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
        
        [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsRoutesSectionValues] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
    }
}

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSString *value = [self getItem:indexPath][@"value"];
    if (_routesSettingType == ERoutesSettingCycle)
    {
        OAMapStyleParameter *cycleNode = [_styleSettings getParameter:CYCLE_NODE_NETWORK_ROUTES_ATTR];
        if (cycleNode && ![cycleNode.value isEqualToString:value])
        {
            [_settings.cycleRoutesParameter set:value];
            cycleNode.value = value;
            [_styleSettings save:cycleNode];
        }
        if (![_routesParameter.value isEqualToString:@"true"])
        {
            _routesParameter.value = @"true";
            [_styleSettings save:_routesParameter];
        }
    }
    else if (_routesSettingType == ERoutesSettingMountain)
    {
        OAMapStyleParameter *mtbScale = [_styleSettings getParameter:SHOW_MTB_SCALE];
        BOOL isMTBEnable = mtbScale && [[self getItem:indexPath][@"title"] isEqualToString:mtbScale.title];
        if (mtbScale)
        {
            mtbScale.value = isMTBEnable ? @"true" : @"false";
            if (isMTBEnable)
                [_settings.mountainBikeRoutesParameter set:mtbScale.name];
            [_styleSettings save:mtbScale];
        }
        OAMapStyleParameter *mtbScaleUphill = [_styleSettings getParameter:SHOW_MTB_SCALE_UPHILL];
        if (mtbScaleUphill)
        {
            mtbScaleUphill.value = isMTBEnable ? @"true" : @"false";
            [_styleSettings save:mtbScaleUphill];
        }
        OAMapStyleParameter *imbaTrails = [_styleSettings getParameter:SHOW_MTB_SCALE_IMBA_TRAILS];
        if (imbaTrails)
        {
            imbaTrails.value = !isMTBEnable ? @"true" : @"false";
            if (!isMTBEnable)
                [_settings.mountainBikeRoutesParameter set:imbaTrails.name];
            [_styleSettings save:imbaTrails];
        }
        [self initData];
    }
    else if (_routesSettingType == ERoutesSettingDifficultyClassification)
    {
        _routesParameter.value = value;
        [_styleSettings save:_routesParameter];
        [self initData];
    }
    else
    {
        if (![_routesParameter.value isEqualToString:value])
        {
            [_settings.hikingRoutesParameter set:value];
            _routesParameter.value = value;
            [_styleSettings save:_routesParameter];
        }
    }
    [UIView setAnimationsEnabled:NO];
    [tblView reloadSections:[NSIndexSet indexSetWithIndex:EOAMapSettingsRoutesSectionValues] withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
