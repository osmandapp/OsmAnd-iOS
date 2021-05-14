//
//  OADefaultSpeedViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADefaultSpeedViewController.h"
#import "OATimeTableViewCell.h"
#import "OASliderWithValuesCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAndApp.h"
#import "OsmAndAppImpl.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"

#define kCellTypeSpeed @"time_cell"
#define kCellTypeSlider @"OASliderWithValuesCell"

@interface OADefaultSpeedViewController()

@end

@implementation OADefaultSpeedViewController
{
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
    
    NSDictionary *_speedParameters;
    CGFloat _ratio;
    NSInteger _maxValue;
    NSInteger _minValue;
    NSInteger _defaultValue;
    NSInteger _selectedValue;
    NSString *_units;
}

- (instancetype) initWithApplicationMode:(OAApplicationMode *)am speedParameters:(NSDictionary *)speedParameters
{
    self = [super initWithAppMode:am];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _speedParameters = speedParameters;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"default_speed");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) generateData
{
    _units = [OASpeedConstant toShortString:[_settings.speedSystem get:self.appMode]];
    switch ([_settings.speedSystem get:self.appMode])
    {
        case MILES_PER_HOUR:
            _ratio = 3600. / METERS_IN_ONE_MILE;
            break;
        case KILOMETERS_PER_HOUR:
            _ratio = 3600. / METERS_IN_KILOMETER;
            break;
        case MINUTES_PER_KILOMETER:
            _ratio = 3600. / METERS_IN_KILOMETER;
            _units = OALocalizedString(@"units_kmh");
            break;
        case NAUTICALMILES_PER_HOUR:
            _ratio = 3600. / METERS_IN_ONE_NAUTICALMILE;
            break;
        case MINUTES_PER_MILE:
            _ratio = 3600. / METERS_IN_ONE_MILE;
            _units = OALocalizedString(@"units_mph");
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

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    if (_selectedValue == 0)
        _selectedValue = _defaultValue;
    [tableData addObject:@{
        @"type" : kCellTypeSpeed,
        @"title" : OALocalizedString(@"default_speed"),
        @"value" : [NSString stringWithFormat:@"%ld %@", _selectedValue, _units],
    }];
    [tableData addObject:@{
        @"type" : kCellTypeSlider,
        @"minValue" : [NSString stringWithFormat:@"%ld %@", (long)_minValue, _units],
        @"maxValue" : [NSString stringWithFormat:@"%ld %@", (long)_maxValue, _units],
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (IBAction) doneButtonPressed:(id)sender
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [self.appMode setDefaultSpeed:_selectedValue / _ratio];
    if (self.appMode == [routingHelper getAppMode] && ([routingHelper isRouteCalculated] || [routingHelper isRouteBeingCalculated]))
        [routingHelper recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeSpeed])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.lbTime.textColor = UIColor.blackColor;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeSlider])
    {
        static NSString* const identifierCell = @"OASliderWithValuesCell";
        OASliderWithValuesCell* cell = nil;
        cell = (OASliderWithValuesCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASliderWithValuesCell" owner:self options:nil];
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
            [cell.sliderView addTarget:self action:@selector(speedValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.tableView reloadData];
    } completion:nil];
}

- (void) speedValueChanged:(UISlider *)sender
{
    if (sender)
    {
        _selectedValue = sender.value;
        [self setupView];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - TableView

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [self getTableHeaderViewWithText:OALocalizedString(@"default_speed_dialog_msg")];
}

@end
