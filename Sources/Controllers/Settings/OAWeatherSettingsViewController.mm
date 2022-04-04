//
//  OAWeatherSettingsViewController.mm
//  OsmAnd
//
//  Created by Skalii on 31.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherSettingsViewController.h"
#import "OAWeatherBandSettingsViewController.h"
#import "OAIconTitleValueCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAWeatherBand.h"
#import "OAWeatherHelper.h"

@interface OAWeatherSettingsViewController () <OAWeatherBandSettingsDelegate>

@end

@implementation OAWeatherSettingsViewController
{
    NSArray<NSDictionary *> *_data;
    NSIndexPath *_selectedIndexPath;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"shared_string_settings");
    self.subtitleLabel.text = OALocalizedString(@"product_title_weather");
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);

    [self setupView];
}

- (void)setupView
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];
    for (OAWeatherBand *band in [OAWeatherHelper sharedInstance].bands)
    {
        [data addObject:@{
                @"band": band,
                @"type": [OAIconTitleValueCell getCellIdentifier]
        }];
    }
    _data = data;
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

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"measurement_units");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:YES];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            OAWeatherBand *band = (OAWeatherBand *) item[@"band"];
            cell.textView.text = [band getMeasurementName];
            cell.leftIconView.image = [UIImage templateImageNamed:[band getIcon]];

            NSUnit *unit = [band getBandUnit];
            if (band.bandIndex == WEATHER_BAND_TEMPERATURE)
                cell.descriptionView.text = unit.name != nil ? unit.name : unit.symbol;
            else
                cell.descriptionView.text = unit.symbol;
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
    NSDictionary *item = _data[indexPath.row];
    _selectedIndexPath = indexPath;
    OAWeatherBandSettingsViewController *controller =
            [[OAWeatherBandSettingsViewController alloc] initWithWeatherBand:item[@"band"]];
    controller.bandDelegate = self;
    [self presentViewController:controller animated:YES completion:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAWeatherBandSettingsDelegate

- (void)onBandUnitChanged
{
    if (_selectedIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
