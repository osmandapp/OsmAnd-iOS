//
//  OAWeatherFrequencySettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 11.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherFrequencySettingsViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAWeatherHelper.h"
#import "OAWorldRegion.h"
#import "OAColors.h"
#import "Localization.h"

#define kFrequencySemiDailyIndex 0
#define kFrequencyDailyIndex 1
#define kFrequencyWeeklyIndex 2

@interface OAWeatherFrequencySettingsViewController () <UIViewControllerTransitioningDelegate>

@end

@implementation OAWeatherFrequencySettingsViewController
{
    OAWorldRegion *_region;
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *_data;
    NSInteger _indexSelected;
}

#pragma mark - Initialization

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super init];
    if (self)
    {
        _region = region;
    }
    return self;
}

- (void)commonInit
{
    EOAWeatherForecastUpdatesFrequency frequency = [OAWeatherHelper getPreferenceFrequency:[OAWeatherHelper checkAndGetRegionId:_region]];
    _indexSelected = frequency == EOAWeatherForecastUpdatesSemiDaily ? kFrequencySemiDailyIndex
            : frequency == EOAWeatherForecastUpdatesDaily ? kFrequencyDailyIndex
                    : kFrequencyWeeklyIndex;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    self.tableView.tableHeaderView =
            [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"weather_generates_new_forecast_description")
                                                 font:kHeaderDescriptionFont
                                            textColor:UIColorFromRGB(color_text_footer)
                                           isBigTitle:NO
                                            topOffset:24.
                                         bottomOffset:12.
                                        rightIconName:nil
                                            tintColor:nil];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_updates_frequency");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *frequencyCells = [NSMutableArray array];
    NSMutableDictionary *frequencySection = [NSMutableDictionary dictionary];
    frequencySection[@"header"] = OALocalizedString(@"shared_string_updates_frequency");
    frequencySection[@"key"] = @"title_section";
    frequencySection[@"cells"] = frequencyCells;
    frequencySection[@"footer"] = [NSString stringWithFormat:@"%@: %@",
            OALocalizedString(@"shared_string_next_update"),
            [OAWeatherHelper getUpdatesDateFormat:[OAWeatherHelper checkAndGetRegionId:_region] next:YES]];
    [data addObject:frequencySection];

    NSMutableDictionary *semiDailyData = [NSMutableDictionary dictionary];
    semiDailyData[@"key"] = @"semi_daily_cell";
    semiDailyData[@"type"] = [OASettingsTitleTableViewCell getCellIdentifier];
    semiDailyData[@"title"] = [OAWeatherHelper getFrequencyFormat:EOAWeatherForecastUpdatesSemiDaily];
    [frequencyCells addObject:semiDailyData];

    NSMutableDictionary *dailyData = [NSMutableDictionary dictionary];
    dailyData[@"key"] = @"daily_cell";
    dailyData[@"type"] = [OASettingsTitleTableViewCell getCellIdentifier];
    dailyData[@"title"] = [OAWeatherHelper getFrequencyFormat:EOAWeatherForecastUpdatesDaily];
    [frequencyCells addObject:dailyData];

    NSMutableDictionary *weeklyData = [NSMutableDictionary dictionary];
    weeklyData[@"key"] = @"weekly_cell";
    weeklyData[@"type"] = [OASettingsTitleTableViewCell getCellIdentifier];
    weeklyData[@"title"] = [OAWeatherHelper getFrequencyFormat:EOAWeatherForecastUpdatesWeekly];
    [frequencyCells addObject:weeklyData];

    _data = data;
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
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OASettingsTitleTableViewCell *) nib[0];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.hidden = indexPath.row != _indexSelected;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    _indexSelected = indexPath.row;
    [OAWeatherHelper setPreferenceFrequency:[OAWeatherHelper checkAndGetRegionId:_region]
                                      value:_indexSelected == kFrequencySemiDailyIndex ? EOAWeatherForecastUpdatesSemiDaily
                                              : _indexSelected == kFrequencyDailyIndex ? EOAWeatherForecastUpdatesDaily
                                                      : EOAWeatherForecastUpdatesWeekly];
    if (self.frequencyDelegate)
        [self.frequencyDelegate onFrequencySelected];

    [self dismissViewController];
}

@end
