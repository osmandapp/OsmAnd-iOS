//
//  OAAngleStraightLineViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 30.11.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAAngleStraightLineViewController.h"
#import "OAValueTableViewCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OASegmentedSlider.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAApplicationMode.h"
#import "OAColors.h"
#import "Localization.h"

#define kAngleMinValue 0.
#define kAngleMaxValue 90.
#define kAngleStepValue 5

@implementation OAAngleStraightLineViewController
{
    OATableDataModel *_data;
    OAAppSettings *_settings;
    NSInteger _selectedValue;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    _selectedValue = (NSInteger) [self.appMode getStrAngle];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"recalc_angle_dialog_title");
}

- (NSString *)getSubtitle
{
    return @"";
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
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *sliderSection = [OATableSectionData sectionData];
    sliderSection.footerText = OALocalizedString(@"recalc_angle_dialog_descr");
    [sliderSection addRowFromDictionary:@{
        kCellTypeKey: [OASegmentSliderTableViewCell getCellIdentifier],
        kCellTitleKey: OALocalizedString(@"shared_string_angle"),
        @"value" : [NSString stringWithFormat:@"%ld°", _selectedValue],
        @"minValue" : [NSString stringWithFormat:@"%d°", (int) kAngleMinValue],
        @"maxValue" : [NSString stringWithFormat:@"%d°", (int) kAngleMaxValue],
        @"marksCount" : @((kAngleMaxValue / kAngleStepValue) + 1),
        @"selectedMark" : @(_selectedValue / kAngleStepValue)
    }];
    [_data addSection:sliderSection];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell =
                [self.tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *) nib[0];
        }
        if (cell)
        {
            cell.topLeftLabel.text = item.title;
            cell.topRightLabel.text = [item stringForKey:@"value"];
            cell.topRightLabel.textColor = UIColorFromRGB(color_primary_purple);
            cell.topRightLabel.font = [UIFont scaledSystemFontOfSize:17 weight:UIFontWeightMedium];
            cell.bottomLeftLabel.text = [item stringForKey:@"minValue"];
            cell.bottomRightLabel.text = [item stringForKey:@"maxValue"];

            [cell.sliderView setNumberOfMarks:[item integerForKey:@"marksCount"] additionalMarksBetween:0];
            cell.sliderView.selectedMark = [item integerForKey:@"selectedMark"];
            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            [cell.sliderView addTarget:self
                                action:@selector(sliderChanged:)
                      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [self.appMode setStrAngle:_selectedValue];
    if (self.delegate)
        [self.delegate onSettingsChanged];
    if (self.appMode == [routingHelper getAppMode] && ([routingHelper isRouteCalculated] || [routingHelper isRouteBeingCalculated]))
        [routingHelper recalculateRouteDueToSettingsChange];
    [self dismissViewController];
}

- (void)sliderChanged:(UISlider *)sender
{
    UISlider *slider = (UISlider *) sender;
    if (slider)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:slider.tag & 0x3FF inSection:slider.tag >> 10];
        OASegmentSliderTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        _selectedValue = cell.sliderView.selectedMark * kAngleStepValue;
        [self generateData];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
