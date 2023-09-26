//
//  OAWeatherAutoUpdateSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWeatherAutoUpdateSettingsViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAWeatherHelper.h"
#import "OAWorldRegion.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAWeatherAutoUpdateSettingsViewController () <UIViewControllerTransitioningDelegate>

@end

@implementation OAWeatherAutoUpdateSettingsViewController
{
    OAWorldRegion *_region;
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *_data;
    EOAWeatherAutoUpdate _autoUpdateStateSelected;
}

#pragma mark - Initialization

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super init];
    if (self)
    {
        _region = region;
        [self configure];
    }
    return self;
}

- (void)configure
{
    _autoUpdateStateSelected = [OAWeatherHelper getPreferenceWeatherAutoUpdate:[OAWeatherHelper checkAndGetRegionId:_region]];
}

#pragma mark - Base UI

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_close");
}

- (NSString *)getTitle
{
    return OALocalizedString(@"auto_update");
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"weather_generates_new_forecast_description");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *data = [NSMutableArray array];
    NSMutableArray<NSMutableDictionary *> *autoUpdateCells = [NSMutableArray array];
    NSMutableDictionary *autoUpdateSection = [NSMutableDictionary dictionary];
    autoUpdateSection[@"key"] = @"title_section";
    autoUpdateSection[@"cells"] = autoUpdateCells;
    autoUpdateSection[@"footer"] = [self getFooterTitle];
    [data addObject:autoUpdateSection];

    NSMutableDictionary *disabledData = [NSMutableDictionary dictionary];
    disabledData[@"key"] = @"disabled_cell";
    disabledData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    disabledData[@"title"] = [OAWeatherHelper getPreferenceWeatherAutoUpdateString:EOAWeatherAutoUpdateDisabled];
    disabledData[@"auto_update_type"] = @(EOAWeatherAutoUpdateDisabled);
    [autoUpdateCells addObject:disabledData];

    NSMutableDictionary *wifiData = [NSMutableDictionary dictionary];
    wifiData[@"key"] = @"wifi_cell";
    wifiData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    wifiData[@"title"] = [OAWeatherHelper getPreferenceWeatherAutoUpdateString:EOAWeatherAutoUpdateOverWIFIOnly];
    wifiData[@"auto_update_type"] = @(EOAWeatherAutoUpdateOverWIFIOnly);
    [autoUpdateCells addObject:wifiData];

    NSMutableDictionary *anyNetworkData = [NSMutableDictionary dictionary];
    anyNetworkData[@"key"] = @"weekly_cell";
    anyNetworkData[@"type"] = [OASimpleTableViewCell getCellIdentifier];
    anyNetworkData[@"title"] = [OAWeatherHelper getPreferenceWeatherAutoUpdateString:EOAWeatherAutoUpdateOverAnyNetwork];
    anyNetworkData[@"auto_update_type"] = @(EOAWeatherAutoUpdateOverAnyNetwork);
    [autoUpdateCells addObject:anyNetworkData];

    _data = data;
}

- (NSString *)getFooterTitle
{
    EOAWeatherAutoUpdate state = [OAWeatherHelper getPreferenceWeatherAutoUpdate:[OAWeatherHelper checkAndGetRegionId:_region]];
    
    NSString *result = @"weather_update_parameters_disabled";
    switch (state) {
        case EOAWeatherAutoUpdateOverWIFIOnly:
            result = @"weather_update_parameters_wifi";
            break;
        case EOAWeatherAutoUpdateOverAnyNetwork:
            result = @"weather_update_parameters_any_network";
            break;
        default:break;
    }
    return OALocalizedString(result);
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _data[section][@"header"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _data[section][@"footer"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.accessoryType = [item[@"auto_update_type"] integerValue] == _autoUpdateStateSelected
            ? UITableViewCellAccessoryCheckmark
            : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    _autoUpdateStateSelected = (EOAWeatherAutoUpdate)[item[@"auto_update_type"] integerValue];
    [OAWeatherHelper setPreferenceWeatherAutoUpdate:[OAWeatherHelper checkAndGetRegionId:_region] value:_autoUpdateStateSelected];
    if (self.autoUpdateDelegate)
        [self.autoUpdateDelegate onAutoUpdateSelected];

    [self dismissViewController];
}

@end
