//
//  OAWeatherBandSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 31.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherBandSettingsViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OASettingsTitleTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"
#import "OsmAndApp.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

@interface OAWeatherBandSettingsViewController () <UIViewControllerTransitioningDelegate>
@end

@implementation OAWeatherBandSettingsViewController
{
    NSArray<NSDictionary *> *_data;
    OAWeatherBand *_band;
    NSInteger _indexSelected;
}

- (instancetype)initWithWeatherBand:(OAWeatherBand *)band
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        _band = band;
        _indexSelected = [_band isBandUnitAuto] ? 0 : [[_band getAvailableBandUnits] indexOfObject:[_band getBandUnit]] + 1;
    }
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    switch (_band.bandIndex)
    {
        case WEATHER_BAND_TEMPERATURE:
            self.titleLabel.text = OALocalizedString(@"map_settings_weather_temp");
            break;
        case WEATHER_BAND_PRESSURE:
            self.titleLabel.text = OALocalizedString(@"map_settings_weather_pressure");
            break;
        case WEATHER_BAND_WIND_SPEED:
            self.titleLabel.text = OALocalizedString(@"map_settings_weather_wind");
            break;
        case WEATHER_BAND_CLOUD:
            self.titleLabel.text = OALocalizedString(@"map_settings_weather_cloud");
            break;
        case WEATHER_BAND_PRECIPITATION:
            self.titleLabel.text = OALocalizedString(@"map_settings_weather_precip");
            break;
        default:
            self.titleLabel.text = OALocalizedString(@"product_title_weather");
            break;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.sectionHeaderHeight = 34.;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];

    [self setupView];
}

- (void)setupView
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;

    NSUnit *unitDefault = [_band getDefaultBandUnit];
    NSString *nameDefault = OALocalizedString(@"device_settings");
    NSString *unitDefaultStr = [NSString stringWithFormat:@" (%@)", [formatter stringFromUnit:unitDefault]];

    [data addObject:@{
            @"unit": unitDefault,
            @"name": OALocalizedString(@"map_settings_weather_temp"),
            @"attributed_title": [self getAttributedNameUnit:nameDefault unit:unitDefaultStr],
            @"type": [OASettingsTitleTableViewCell getCellIdentifier]
    }];

    NSArray<NSUnit *> *units = [_band getAvailableBandUnits];
    for (NSInteger i = 0; i < units.count; i++)
    {
        NSUnit *unit = units[i];
        NSString *name = unit.name != nil ? unit.name : [formatter stringFromUnit:unit];
        NSString *unitStr = unit.name != nil ? [NSString stringWithFormat:@" (%@)", [formatter stringFromUnit:unit]] : nil;

        [data addObject:@{
                @"unit": unit,
                @"name": OALocalizedString(@"map_settings_weather_temp"),
                @"attributed_title": [self getAttributedNameUnit:name unit:unitStr],
                @"type": [OASettingsTitleTableViewCell getCellIdentifier]
        }];
    }

    _data = data;
}

- (NSAttributedString *)getAttributedNameUnit:(NSString *)name unit:(NSString *)unit
{
    NSDictionary *nameAttributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:17.0],
            NSForegroundColorAttributeName : UIColor.blackColor
    };
    NSDictionary *unitAttributes = @{
            NSFontAttributeName : [UIFont systemFontOfSize:17.0],
            NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)
    };

    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:nameAttributes]];
    if (unit)
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:unit attributes:unitAttributes]];

    return attributedString;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
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
            cell.textView.attributedText = item[@"attributed_title"];
            cell.iconView.hidden = indexPath.row != _indexSelected;
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];
    return outCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _indexSelected = indexPath.row;

    [_band setBandUnitAuto:_indexSelected == 0];
    if (_indexSelected != 0)
        [_band setBandUnit:_data[indexPath.row][@"unit"]];

    [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->setBandSettings([[OAWeatherHelper sharedInstance] getBandSettings]);
    if (self.bandDelegate)
        [self.bandDelegate onBandUnitChanged];

    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
             withRowAnimation:UITableViewRowAnimationNone];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return _band.bandIndex == WEATHER_BAND_CLOUD
            ? [OATableViewCustomFooterView getHeight:OALocalizedString(@"weather_cloud_data_description")
                                               width:self.tableView.bounds.size.width]
            : 0.001;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (_band.bandIndex != WEATHER_BAND_CLOUD)
        return nil;

    OATableViewCustomFooterView *vw =
            [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString *textStr =
            [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"weather_cloud_data_description")
                                                   attributes:@{
                                    NSFontAttributeName: textFont,
                                    NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
            }];
    vw.label.attributedText = textStr;
    return vw;
}

@end
