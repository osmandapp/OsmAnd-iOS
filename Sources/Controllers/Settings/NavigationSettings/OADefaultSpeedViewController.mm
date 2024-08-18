//
//  OADefaultSpeedViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADefaultSpeedViewController.h"
#import "OAValueTableViewCell.h"
#import "OASliderWithValuesCell.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndApp.h"
#import "OsmAndAppImpl.h"
#import "OARoutingHelper.h"
#import "OAOsmAndFormatter.h"
#import "GeneratedAssetSymbols.h"

@implementation OADefaultSpeedViewController
{
    NSArray<NSDictionary *> *_data;

    NSDictionary *_speedParameters;
    CGFloat _ratio;
    NSInteger _maxValue;
    NSInteger _minValue;
    NSInteger _defaultValue;
    NSInteger _selectedValue;
    NSString *_units;
}

#pragma mark - Initialization

- (instancetype)initWithApplicationMode:(OAApplicationMode *)am speedParameters:(NSDictionary *)speedParameters
{
    self = [super initWithAppMode:am];
    if (self)
    {
        _speedParameters = speedParameters;
        [self postInit];
    }
    return self;
}

- (void)postInit
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    _units = [OASpeedConstant toShortString:[settings.speedSystem get:self.appMode]];
    switch ([settings.speedSystem get:self.appMode])
    {
        case MILES_PER_HOUR:
            _ratio = 3600. / METERS_IN_ONE_MILE;
            break;
        case KILOMETERS_PER_HOUR:
            _ratio = 3600. / METERS_IN_KILOMETER;
            break;
        case MINUTES_PER_KILOMETER:
            _ratio = 3600. / METERS_IN_KILOMETER;
            _units = OALocalizedString(@"km_h");
            break;
        case NAUTICALMILES_PER_HOUR:
            _ratio = 3600. / METERS_IN_ONE_NAUTICALMILE;
            break;
        case MINUTES_PER_MILE:
            _ratio = 3600. / METERS_IN_ONE_MILE;
            _units = OALocalizedString(@"mile_per_hour");
            break;
        case METERS_PER_SECOND:
            _ratio = 1;
            break;
    }

    CGFloat settingsDefaultSpeed = self.appMode.getDefaultSpeed;

    auto router = [OsmAndApp.instance getRouter:self.appMode];
    if (!router || self.appMode.getRouterService == STRAIGHT || self.appMode.getRouterService == DIRECT_TO)
    {
        _minValue = round(MIN(1, settingsDefaultSpeed) * _ratio);
        _maxValue = round(MAX(300, settingsDefaultSpeed) * _ratio);
    }
    else
    {
        _minValue = round(router->getMinSpeed() * _ratio / 2.);
        _maxValue = round(router->getMaxSpeed() * _ratio * 1.5);
    }
    _defaultValue = round(self.appMode.getDefaultSpeed * _ratio);
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"default_speed_setting_title");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    if (_selectedValue == 0)
        _selectedValue = _defaultValue;
    [tableData addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"default_speed_setting_title"),
        @"value" : [NSString stringWithFormat:@"%ld %@", _selectedValue, _units],
    }];
    [tableData addObject:@{
        @"type" : [OASliderWithValuesCell getCellIdentifier],
        @"minValue" : [NSString stringWithFormat:@"%ld %@", (long)_minValue, _units],
        @"maxValue" : [NSString stringWithFormat:@"%ld %@", (long)_maxValue, _units],
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return OALocalizedString(@"default_speed_dialog_msg");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASliderWithValuesCell getCellIdentifier]])
    {
        OASliderWithValuesCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASliderWithValuesCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASliderWithValuesCell getCellIdentifier] owner:self options:nil];
            cell = (OASliderWithValuesCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.sliderView.continuous = YES;
        }
        if (cell)
        {
            cell.leftValueLabel.text = item[@"minValue"];
            cell.rightValueLabel.text = item[@"maxValue"];
            cell.sliderView.minimumValue = _minValue;
            cell.sliderView.maximumValue = _maxValue;
            cell.sliderView.value = _selectedValue;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.sliderView addTarget:self action:@selector(speedValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return 1;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [self.appMode setDefaultSpeed:_selectedValue / _ratio];
    if (self.appMode == [routingHelper getAppMode] && ([routingHelper isRouteCalculated] || [routingHelper isRouteBeingCalculated]))
        [routingHelper recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

- (void)speedValueChanged:(UISlider *)sender
{
    _selectedValue = sender.value;
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
