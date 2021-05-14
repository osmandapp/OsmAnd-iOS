//
//  OARoadSpeedsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 17.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoadSpeedsViewController.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAndApp.h"
#import "OsmAndAppImpl.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"

#import "OATimeTableViewCell.h"
#import "OASliderWithValuesCell.h"
#import "OARangeSliderCell.h"

#define kSidePadding 16
#define kTopPadding 16

@interface OARoadSpeedsViewController() <UITableViewDelegate, UITableViewDataSource, TTRangeSliderDelegate>

@end

@implementation OARoadSpeedsViewController
{
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
    NSDictionary *_speedParameters;
    
    CGFloat _ratio;
    NSInteger _maxValue;
    NSInteger _minValue;
    NSInteger _baseMinSpeed;
    NSInteger _baseMaxSpeed;
    NSString *_units;
    NSAttributedString *_footerAttrString;
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

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.backButton.hidden = YES;
    self.cancelButton.hidden = NO;
    self.doneButton.hidden = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _footerAttrString = [[NSAttributedString alloc] initWithAttributedString: [self getFooterDescription]];
    [self setupTableHeaderViewWithText:OALocalizedString(@"road_speeds_descr")];
    [self setupView];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"road_speeds");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (NSAttributedString *) getFooterDescription
{
    NSString *minimumSpeedDescriptionString = [NSString stringWithFormat:@"%@:\n%@\n", OALocalizedString(@"logging_min_speed"), OALocalizedString(@"road_min_speed_descr")];
    NSString *maximumSpeedDescriptionString = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"maximum_speed"), OALocalizedString(@"road_max_speed_descr")];

    NSMutableAttributedString *minSpeedAttrString = [OAUtilities getStringWithBoldPart:minimumSpeedDescriptionString mainString:OALocalizedString(@"road_min_speed_descr") boldString:OALocalizedString(@"logging_min_speed") lineSpacing:1. fontSize:13.];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setParagraphSpacing:12.];
    CGFloat breakLinePosition = [minimumSpeedDescriptionString indexOf:@"\n"] + 1;
    [minSpeedAttrString addAttribute:NSParagraphStyleAttributeName value: style range:NSMakeRange(breakLinePosition, minimumSpeedDescriptionString.length - breakLinePosition)];
    NSAttributedString *maxSpeedAttrString = [OAUtilities getStringWithBoldPart:maximumSpeedDescriptionString mainString:OALocalizedString(@"road_max_speed_descr") boldString:OALocalizedString(@"maximum_speed") lineSpacing:1. fontSize:13.];
    
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:minSpeedAttrString];
    [finalString appendAttributedString:maxSpeedAttrString];
    return finalString;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"road_speeds_descr")];
        [self.tableView reloadData];
    } completion:nil];
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    auto router = [OARouteProvider getRouter:self.appMode];
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
    CGFloat settingsMinSpeed = self.appMode.getMinSpeed;
    CGFloat settingsMaxSpeed = self.appMode.getMaxSpeed;
    
    CGFloat minSpeedValue = settingsMinSpeed > 0 ? settingsMinSpeed : router->getMinSpeed();
    CGFloat maxSpeedValue = settingsMaxSpeed > 0 ? settingsMaxSpeed : router->getMaxSpeed();

    _minValue = round(minSpeedValue * _ratio);
    _maxValue = round(maxSpeedValue * _ratio);
    
    _baseMinSpeed = round(MIN(_minValue, router->getMinSpeed() * _ratio / 2.));
    _baseMaxSpeed = round(MAX(_maxValue, router->getMaxSpeed() * _ratio * 1.5));
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    [tableData addObject:@{
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"logging_min_speed"),
        @"value" : [NSString stringWithFormat:@"%ld %@", _minValue, _units],
    }];
    [tableData addObject:@{
        @"type" : [OATimeTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"maximum_speed"),
        @"value" : [NSString stringWithFormat:@"%ld %@", _maxValue, _units],
    }];
    [tableData addObject:@{
        @"type" : [OASliderWithValuesCell getCellIdentifier],
        @"minValue" : [NSString stringWithFormat:@"%ld %@", _baseMinSpeed, _units],
        @"maxValue" : [NSString stringWithFormat:@"%ld %@", _baseMaxSpeed, _units],
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (IBAction) doneButtonPressed:(id)sender
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [self.appMode setMinSpeed:(_minValue / _ratio)];
    [self.appMode setMaxSpeed:(_maxValue / _ratio)];
    if (self.appMode == [routingHelper getAppMode] && ([routingHelper isRouteCalculated] || [routingHelper isRouteBeingCalculated]))
        [routingHelper recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OATimeTableViewCell getCellIdentifier]])
    {
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATimeTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATimeTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.lbTime.textColor = UIColor.blackColor;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        return cell;
    }
    else if ([cellType isEqualToString:[OASliderWithValuesCell getCellIdentifier]])
    {
        OARangeSliderCell* cell = nil;
        cell = (OARangeSliderCell *)[tableView dequeueReusableCellWithIdentifier:[OARangeSliderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARangeSliderCell getCellIdentifier] owner:self options:nil];
            cell = (OARangeSliderCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.minLabel.text = OALocalizedString(@"shared_string_min");
            cell.maxLabel.text = OALocalizedString(@"shared_string_max");
        }
        if (cell)
        {
            cell.rangeSlider.delegate = self;
            cell.rangeSlider.minValue = _baseMinSpeed;
            cell.rangeSlider.maxValue = _baseMaxSpeed;
            cell.rangeSlider.selectedMinimum = _minValue;
            cell.rangeSlider.selectedMaximum = _maxValue;
            cell.minValueLabel.text = item[@"minValue"];
            cell.maxValueLabel.text = item[@"maxValue"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [OAUtilities calculateTextBounds:_footerAttrString width:textWidth].height + kTopPadding;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight)];
    UILabel *footerDescription = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 0., textWidth, textHeight)];
    footerDescription.attributedText = [[NSAttributedString alloc] initWithAttributedString:_footerAttrString];
    footerDescription.numberOfLines = 0;
    footerDescription.lineBreakMode = NSLineBreakByWordWrapping;
    footerDescription.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    footerDescription.textColor = UIColorFromRGB(color_text_footer);
    [vw addSubview:footerDescription];
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities calculateTextBounds:_footerAttrString width:textWidth].height + kTopPadding;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

#pragma mark TTRangeSliderViewDelegate

- (void) rangeSlider:(TTRangeSlider *)sender didChangeSelectedMinimumValue:(float)selectedMinimum andMaximumValue:(float)selectedMaximum
{
    _minValue = selectedMinimum;
    _maxValue = selectedMaximum;
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
