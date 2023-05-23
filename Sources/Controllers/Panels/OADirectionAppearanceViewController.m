//
//  OADirectionAppearanceViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 14.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADirectionAppearanceViewController.h"
#import "OARootViewController.h"
#import "OAAppSettings.h"
#import "OASwitchTableViewCell.h"
#import "OASettingsCheckmarkCell.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapPanelViewController.h"

#include "Localization.h"
#include "OAColors.h"

#define kActiveMarkers @"activeMarkers"
#define kOneActiveMarker @"oneActiveMarker"
#define kTwoActiveMarkers @"twoActiveMarkers"
#define kDistanceIndication @"distanceIndication"
#define kTopBarDisplay @"topBarDisplay"
#define kWidgetDisplay @"widgetDisplay"
#define kArrowsOnMap @"arrows"
#define kLinesOnMap @"lines"

@implementation OADirectionAppearanceViewController
{
    NSDictionary *_data;
    OAAppSettings *_settings;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    OAMapPanelViewController *_mapPanel;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    _mapPanel = [OARootViewController instance].mapPanel;
}

#pragma mark - UIViewColontroller

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_mapPanel recreateControls];
    [_mapPanel refreshMap:YES];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_appearance");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [NSMutableDictionary dictionary];
    
    NSMutableArray *activeMarkersArr = [NSMutableArray array];
    NSMutableArray *distanceIndicationArr = [NSMutableArray array];
    NSMutableArray *appearanceOnMapArr = [NSMutableArray array];

    [activeMarkersArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kActiveMarkers,
                        @"key" : kOneActiveMarker,
                        @"title" : OALocalizedString(@"shared_string_one"),
                        @"img" : [self drawDeviceImage:@"ic_custom_direction_topbar_one" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_inactive" : [self drawDeviceImage:@"ic_custom_direction_topbar_one" bgColor:UIColorFromRGB(color_tint_gray)]
                        }];
    
    [activeMarkersArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kActiveMarkers,
                        @"key" : kTwoActiveMarkers,
                        @"title" : OALocalizedString(@"shared_string_two"),
                        @"img" : [self drawDeviceImage:@"ic_custom_direction_topbar_two" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_inactive" : [self drawDeviceImage:@"ic_custom_direction_topbar_two"  bgColor:UIColorFromRGB(color_tint_gray)]
                        }];

    [distanceIndicationArr addObject:@{
                        @"type" : [OASwitchTableViewCell getCellIdentifier],
                        @"key" : kDistanceIndication,
                        @"value" : @([_settings.distanceIndicationVisibility get]),
                        @"title" : OALocalizedString(@"show_direction"),
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kDistanceIndication,
                        @"key" : kTopBarDisplay,
                        @"title" : OALocalizedString(@"shared_string_topbar"),
                        @"img_one" : [self drawDeviceImage:@"ic_custom_direction_topbar_one" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_one_inactive" : [self drawDeviceImage:@"ic_custom_direction_topbar_one" bgColor:UIColorFromRGB(color_tint_gray)],
                        @"img_two" : [self drawDeviceImage:@"ic_custom_direction_topbar_two" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_two_inactive" : [self drawDeviceImage:@"ic_custom_direction_topbar_two" bgColor:UIColorFromRGB(color_tint_gray)]
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kDistanceIndication,
                        @"key" : kWidgetDisplay,
                        @"title" : OALocalizedString(@"shared_string_widgets"),
                        @"img_one" : [self drawDeviceImage:@"ic_custom_direction_widget_one" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_one_inactive" : [self drawDeviceImage:@"ic_custom_direction_widget_one" bgColor:UIColorFromRGB(color_tint_gray)],
                        @"img_two" : [self drawDeviceImage:@"ic_custom_direction_widget_two" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_two_inactive" : [self drawDeviceImage:@"ic_custom_direction_widget_two" bgColor:UIColorFromRGB(color_tint_gray)]
                        }];
   
    [appearanceOnMapArr addObject:@{
                        @"type" : [OASwitchTableViewCell getCellIdentifier],
                        @"key" : kArrowsOnMap,
                        @"value" : @([_settings.arrowsOnMap get]),
                        @"title" : OALocalizedString(@"arrows_on_map"),
                        }];
    
    [appearanceOnMapArr addObject:@{
                        @"type" : [OASwitchTableViewCell getCellIdentifier],
                        @"key" : kLinesOnMap,
                        @"value" : @([_settings.directionLines get]),
                        @"title" : OALocalizedString(@"direction_lines"),
                        }];
 
    _data = @{ @"appearanceOnMap" : appearanceOnMapArr,
               @"distanceIndication" : distanceIndicationArr,
               @"activeMarkers" : activeMarkersArr
            };
}

- (UIImage *)drawDeviceImage:(NSString *)fgImage bgColor:(UIColor *)bgColor
 {
     UIImage *fgImg = [UIImage templateImageNamed:fgImage];
     UIImage *bgImg = [UIImage templateImageNamed:@"ic_custom_direction_device"];
     UIColor *fgColor = UIColorFromRGB(color_primary_purple);
     UIGraphicsBeginImageContextWithOptions(bgImg.size, NO, 0.0);
     
     [bgColor setFill];
     [bgImg drawInRect:CGRectMake(0.0, 0.0, bgImg.size.width, bgImg.size.height)];
     [fgColor setFill];
     [fgImg drawInRect:CGRectMake(0.0, 0.0, fgImg.size.width, fgImg.size.height)];
     
     UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     return newImage;
 }

- (NSString *)getTitleForHeader:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"active_markers");
        case 1:
            return OALocalizedString(@"show_direction");
        case 2:
            return OALocalizedString(@"appearance_on_the_map");
        default:
            return @"";
    }
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"specify_number_of_dir_indicators");
        case 1:
            return OALocalizedString(@"choose_how_display_distance");
        case 2:
            return OALocalizedString(@"arrows_direction_to_markers");
        default:
            return @"";
    }
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (![_settings.distanceIndicationVisibility get] && section == 1)
        return 1;
    return [_data[_data.allKeys[section]] count];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OASettingsCheckmarkCell getCellIdentifier]])
    {
        OASettingsCheckmarkCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASettingsCheckmarkCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsCheckmarkCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsCheckmarkCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 50.0, 0.0, 0.0);
        }
        NSString *key = item[@"key"];
        EOADistanceIndicationConstant distanceIndication = [_settings.distanceIndication get];
        EOAActiveMarkerConstant activeMarkers = [_settings.activeMarkers get];
        BOOL selected = NO;
        if ([key isEqualToString:kOneActiveMarker])
        {
            selected = activeMarkers == ONE_ACTIVE_MARKER;
            cell.iconImageView.image = selected ? [item[@"img"] imageFlippedForRightToLeftLayoutDirection] : [item[@"img_inactive"] imageFlippedForRightToLeftLayoutDirection];
        }
        else if ([key isEqualToString:kTwoActiveMarkers])
        {
            selected = activeMarkers == TWO_ACTIVE_MARKERS;
            cell.iconImageView.image = selected ? [item[@"img"] imageFlippedForRightToLeftLayoutDirection] : [item[@"img_inactive"] imageFlippedForRightToLeftLayoutDirection];
        }
        else if ([key isEqualToString:kTopBarDisplay])
        {
            selected = distanceIndication == TOP_BAR_DISPLAY;
            if (activeMarkers == ONE_ACTIVE_MARKER)
                cell.iconImageView.image = selected ? [item[@"img_one"] imageFlippedForRightToLeftLayoutDirection] : [item[@"img_one_inactive"] imageFlippedForRightToLeftLayoutDirection];
            else
                cell.iconImageView.image = selected ? [item[@"img_two"] imageFlippedForRightToLeftLayoutDirection] : [item[@"img_two_inactive"] imageFlippedForRightToLeftLayoutDirection];
        }
        else if ([key isEqualToString:kWidgetDisplay])
        {
            selected = distanceIndication == WIDGET_DISPLAY;
            if (activeMarkers == ONE_ACTIVE_MARKER)
                cell.iconImageView.image = selected ? [item[@"img_one"] imageFlippedForRightToLeftLayoutDirection] : [item[@"img_one_inactive"] imageFlippedForRightToLeftLayoutDirection];
            else
                cell.iconImageView.image = selected ? [item[@"img_two"] imageFlippedForRightToLeftLayoutDirection] : [item[@"img_two_inactive"] imageFlippedForRightToLeftLayoutDirection];
        }
        cell.titleLabel.text = item[@"title"];
        cell.checkmarkImageView.hidden = !selected;
        return cell;
    }
    else
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
        }
        cell.titleLabel.text = item[@"title"];
        [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        if ([item[@"key"] isEqualToString:kDistanceIndication])
        {
            [cell.switchView setOn:[_settings.distanceIndicationVisibility get]];
            [cell.switchView addTarget:self action:@selector(showDistanceIndication:) forControlEvents:UIControlEventValueChanged];
        }
        else if ([item[@"key"] isEqualToString:kArrowsOnMap])
        {
            [cell.switchView setOn:[_settings.arrowsOnMap get]];
            [cell.switchView addTarget:self action:@selector(showArrowsOnMap:) forControlEvents:UIControlEventValueChanged];
        }
        else if ([item[@"key"] isEqualToString:kLinesOnMap])
        {
            [cell.switchView setOn:[_settings.directionLines get]];
            [cell.switchView addTarget:self action:@selector(showLinesOnMap:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];

    if ([item[@"section"] isEqualToString:@"activeMarkers"])
    {
        if (indexPath.row == 0)
            [_settings.activeMarkers set:ONE_ACTIVE_MARKER];
        else
            [_settings.activeMarkers set:TWO_ACTIVE_MARKERS];
        if ([_settings.distanceIndication get] == WIDGET_DISPLAY)
            [self setWidgetVisibility:YES collapsed:NO];
    }
    else if ([item[@"section"] isEqualToString:@"distanceIndication"])
    {
        if (indexPath.row == 1)
        {
            [_settings.distanceIndication set:TOP_BAR_DISPLAY];
            [self setWidgetVisibility:NO collapsed:NO];
        }
        else
        {
            [_settings.distanceIndication set:WIDGET_DISPLAY];
            [self setWidgetVisibility:YES collapsed:NO];
        }
    }
    if ([_settings.distanceIndicationVisibility get])
    {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                 [NSIndexPath indexPathForRow:1 inSection:0],
                                                 [NSIndexPath indexPathForRow:1 inSection:1],
                                                 [NSIndexPath indexPathForRow:2 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                 [NSIndexPath indexPathForRow:1 inSection:0]]
                              withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Additions

- (void)setWidgetVisibility:(BOOL)visible collapsed:(BOOL)collapsed
{
    OAMapWidgetRegInfo *marker1st = [_mapWidgetRegistry widgetByKey:@"map_marker_1st"];
    OAMapWidgetRegInfo *marker2nd = [_mapWidgetRegistry widgetByKey:@"map_marker_2nd"];
    if (marker1st)
        [_mapWidgetRegistry setVisibility:marker1st visible:visible collapsed:collapsed];
    if (marker2nd && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
        [_mapWidgetRegistry setVisibility:marker2nd visible:visible collapsed:collapsed];
    else
        [_mapWidgetRegistry setVisibility:marker2nd visible:NO collapsed:collapsed];
}

#pragma mark - Selectors

- (void)showDistanceIndication:(UISwitch *)sender
{
    if (sender)
        [_settings.distanceIndicationVisibility set:sender.isOn];
    [self generateData];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)showArrowsOnMap:(UISwitch *)sender
{
    if (sender)
        [_settings.arrowsOnMap set:sender.isOn];
}

- (void)showLinesOnMap:(UISwitch *)sender
{
    if (sender)
        [_settings.directionLines set:sender.isOn];
}

@end
