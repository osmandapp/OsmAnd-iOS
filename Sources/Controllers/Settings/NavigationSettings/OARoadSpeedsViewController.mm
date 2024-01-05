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
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndApp.h"
#import "OsmAndAppImpl.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"
#import "OAValueTableViewCell.h"
#import "OASliderWithValuesCell.h"
#import "OARangeSliderCell.h"
#import "GeneratedAssetSymbols.h"

#define kSidePadding 16
#define kTopPadding 16

@interface OARoadSpeedsViewController() <TTRangeSliderDelegate>

@end

@implementation OARoadSpeedsViewController
{
    NSArray<NSDictionary *> *_data;
    OAAppSettings *_settings;
    
    CGFloat _ratio;
    NSInteger _maxValue;
    NSInteger _minValue;
    NSInteger _baseMinSpeed;
    NSInteger _baseMaxSpeed;
    NSString *_units;
    NSAttributedString *_footerAttrString;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _footerAttrString = [[NSAttributedString alloc] initWithAttributedString:[self getFooterDescription]];
}

- (void)postInit
{
    auto router = [OsmAndApp.instance getRouter:self.appMode];
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
    CGFloat settingsMinSpeed = self.appMode.getMinSpeed;
    CGFloat settingsMaxSpeed = self.appMode.getMaxSpeed;
    
    CGFloat minSpeedValue = settingsMinSpeed > 0 ? settingsMinSpeed : router->getMinSpeed();
    CGFloat maxSpeedValue = settingsMaxSpeed > 0 ? settingsMaxSpeed : router->getMaxSpeed();

    _minValue = round(minSpeedValue * _ratio);
    _maxValue = round(maxSpeedValue * _ratio);
    
    _baseMinSpeed = round(MIN(_minValue, router->getMinSpeed() * _ratio / 2.));
    _baseMaxSpeed = round(MAX(_maxValue, router->getMaxSpeed() * _ratio * 1.5));
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"road_speeds");
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

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"road_speeds_descr");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    [tableData addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"monitoring_min_speed"),
        @"value" : [NSString stringWithFormat:@"%ld %@", _minValue, _units],
    }];
    [tableData addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"max_speed"),
        @"value" : [NSString stringWithFormat:@"%ld %@", _maxValue, _units],
    }];
    [tableData addObject:@{
        @"type" : [OASliderWithValuesCell getCellIdentifier],
        @"minValue" : [NSString stringWithFormat:@"%ld %@", _baseMinSpeed, _units],
        @"maxValue" : [NSString stringWithFormat:@"%ld %@", _baseMaxSpeed, _units],
    }];
    _data = [NSArray arrayWithArray:tableData];
}

- (BOOL)hideFirstHeader
{
    return YES;
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
        OARangeSliderCell* cell = nil;
        cell = (OARangeSliderCell *)[self.tableView dequeueReusableCellWithIdentifier:[OARangeSliderCell getCellIdentifier]];
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

- (NSInteger)sectionsCount
{
    return 1;
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + [OAUtilities getLeftMargin]) * 2;
    return [OAUtilities calculateTextBounds:_footerAttrString width:textWidth].height + kTopPadding;
}

- (UIView *)getCustomViewForFooter:(NSInteger)section
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [OAUtilities calculateTextBounds:_footerAttrString width:textWidth].height + kTopPadding;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight)];
    UILabel *footerDescription = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 0., textWidth, textHeight)];
    footerDescription.attributedText = [[NSAttributedString alloc] initWithAttributedString:_footerAttrString];
    footerDescription.numberOfLines = 0;
    footerDescription.lineBreakMode = NSLineBreakByWordWrapping;
    footerDescription.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    footerDescription.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    [vw addSubview:footerDescription];
    return vw;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [self.appMode setMinSpeed:(_minValue / _ratio)];
    [self.appMode setMaxSpeed:(_maxValue / _ratio)];
    if (self.appMode == [routingHelper getAppMode] && ([routingHelper isRouteCalculated] || [routingHelper isRouteBeingCalculated]))
        [routingHelper recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

#pragma mark - Additions

- (NSAttributedString *)getFooterDescription
{
    NSString *minimumSpeedDescriptionString = [NSString stringWithFormat:@"%@:\n%@\n", OALocalizedString(@"monitoring_min_speed"), OALocalizedString(@"road_min_speed_descr")];
    NSString *maximumSpeedDescriptionString = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"max_speed"), OALocalizedString(@"road_max_speed_descr")];

    NSMutableAttributedString *minSpeedAttrString = [OAUtilities getStringWithBoldPart:minimumSpeedDescriptionString mainString:OALocalizedString(@"road_min_speed_descr") boldString:OALocalizedString(@"monitoring_min_speed") lineSpacing:1. fontSize:13.];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setParagraphSpacing:12.];
    CGFloat breakLinePosition = [minimumSpeedDescriptionString indexOf:@"\n"] + 1;
    [minSpeedAttrString addAttribute:NSParagraphStyleAttributeName value: style range:NSMakeRange(breakLinePosition, minimumSpeedDescriptionString.length - breakLinePosition)];
    NSAttributedString *maxSpeedAttrString = [OAUtilities getStringWithBoldPart:maximumSpeedDescriptionString mainString:OALocalizedString(@"road_max_speed_descr") boldString:OALocalizedString(@"max_speed") lineSpacing:1. fontSize:13.];
    
    NSMutableAttributedString *finalString = [[NSMutableAttributedString alloc] initWithAttributedString:minSpeedAttrString];
    [finalString appendAttributedString:maxSpeedAttrString];
    return finalString;
}

#pragma mark TTRangeSliderViewDelegate

- (void) rangeSlider:(TTRangeSlider *)sender didChangeSelectedMinimumValue:(float)selectedMinimum andMaximumValue:(float)selectedMaximum
{
    _minValue = selectedMinimum;
    _maxValue = selectedMaximum;
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

@end
