//
//  OAWeatherBandSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 31.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherBandSettingsViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OASimpleTableViewCell.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"
#import "OsmAndApp.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

@interface OAWeatherBandSettingsViewController () <UIViewControllerTransitioningDelegate>

@end

@implementation OAWeatherBandSettingsViewController
{
    NSArray<NSDictionary *> *_data;
    OAWeatherBand *_band;
    NSInteger _indexSelected;
}

#pragma mark - Initialization

- (instancetype)initWithWeatherBand:(OAWeatherBand *)band
{
    self = [super init];
    if (self)
    {
        _band = band;
        _indexSelected = [_band isBandUnitAuto] ? 0 : [[_band getAvailableBandUnits] indexOfObject:[_band getBandUnit]] + 1;
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return [_band getMeasurementName];
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _band.bandIndex == WEATHER_BAND_CLOUD ? OALocalizedString(@"weather_cloud_data_description") : nil;
}

- (void)generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];

    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;

    NSUnit *unitDefault = [_band getDefaultBandUnit];
    NSString *nameDefault = OALocalizedString(@"device_settings");
    NSString *unitDefaultStr = [NSString stringWithFormat:@" (%@)", [formatter displayStringFromUnit:unitDefault]];

    [data addObject:@{
            @"unit": unitDefault,
            @"attributed_title": [self getAttributedNameUnit:nameDefault unit:unitDefaultStr],
            @"type": [OASimpleTableViewCell getCellIdentifier]
    }];

    NSArray<NSUnit *> *units = [_band getAvailableBandUnits];
    for (NSInteger i = 0; i < units.count; i++)
    {
        NSUnit *unit = units[i];
        NSString *name = unit.name != nil ? unit.name : [formatter displayStringFromUnit:unit];
        NSString *unitStr = unit.name != nil ? [NSString stringWithFormat:@" (%@)", [formatter displayStringFromUnit:unit]] : nil;

        [data addObject:@{
                @"unit": unit,
                @"attributed_title": [self getAttributedNameUnit:name unit:unitStr],
                @"type": [OASimpleTableViewCell getCellIdentifier]
        }];
    }

    _data = data;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier]
                                                     owner:self
                                                   options:nil];
        cell = (OASimpleTableViewCell *) nib[0];
        [cell descriptionVisibility:NO];
        [cell leftIconVisibility:NO];
    }
    if (cell)
    {
        cell.titleLabel.attributedText = item[@"attributed_title"];
        if (indexPath.row == _indexSelected)
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    _indexSelected = indexPath.row;
    NSUnit *prevUnit = [_band getBandUnit];
    [_band setBandUnitAuto:_indexSelected == 0];
    if (_indexSelected != 0)
        [_band setBandUnit:_data[indexPath.row][@"unit"]];
    NSUnit *currentUnit = [_band getBandUnit];

    [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->setBandSettings([[OAWeatherHelper sharedInstance] getBandSettings]);
    if (![prevUnit.symbol isEqualToString:currentUnit.symbol])
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    if (self.bandDelegate)
        [self.bandDelegate onBandUnitChanged];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
             withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Additions

- (NSAttributedString *)getAttributedNameUnit:(NSString *)name unit:(NSString *)unit
{
    NSDictionary *nameAttributes = @{
            NSFontAttributeName : [UIFont scaledSystemFontOfSize:17.0],
            NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
    };
    NSDictionary *unitAttributes = @{
            NSFontAttributeName : [UIFont scaledSystemFontOfSize:17.0],
            NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary]
    };

    NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:nameAttributes]];
    if (unit)
        [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:unit attributes:unitAttributes]];

    return attributedString;
}

@end
