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

@interface OAWeatherFrequencySettingsViewController () <UIViewControllerTransitioningDelegate, UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAWeatherFrequencySettingsViewController
{
    OAWorldRegion *_region;
    NSMutableArray<NSMutableDictionary<NSString *, id> *> *_data;
    NSInteger _indexSelected;
}

- (instancetype)initWithRegion:(OAWorldRegion *)region
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        _region = region;
        [self commonInit];
    }
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"shared_string_updates_frequency");
}

- (void)commonInit
{
    EOAWeatherForecastUpdatesFrequency frequency = [OAWeatherHelper getPreferenceFrequency:[OAWeatherHelper checkAndGetRegionId:_region]];
    _indexSelected = frequency == EOAWeatherForecastUpdatesSemiDaily ? kFrequencySemiDailyIndex
            : frequency == EOAWeatherForecastUpdatesDaily ? kFrequencyDailyIndex
                    : kFrequencyWeeklyIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.sectionHeaderHeight = 34.;
    self.tableView.sectionFooterHeight = 0.001;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    self.tableView.tableHeaderView =
            [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"weather_generates_new_forecast_description")
                                                 font:[UIFont systemFontOfSize:13.]
                                            textColor:UIColorFromRGB(color_text_footer)
                                          lineSpacing:0.0
                                              isTitle:NO
                                                    y:24.];
    self.subtitleLabel.hidden = YES;
    [self setupView];
}

- (void)setupView
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][@"footer"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

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
