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
#import "OATableViewCustomHeaderView.h"
#import "OATableViewCustomFooterView.h"
#import "OASettingSwitchCell.h"
#import "OASettingsCheckmarkCell.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapPanelViewController.h"

#include "Localization.h"
#include "OASizes.h"
#include "OAColors.h"

#define kActiveMarkers @"activeMarkers"
#define kOneActiveMarker @"oneActiveMarker"
#define kTwoActiveMarkers @"twoActiveMarkers"
#define kDistanceIndication @"distanceIndication"
#define kTopBarDisplay @"topBarDisplay"
#define kWidgetDisplay @"widgetDisplay"
#define kArrowsOnMap @"arrows"
#define kLinesOnMap @"lines"

@interface OADirectionAppearanceViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end

@implementation OADirectionAppearanceViewController
{
    NSDictionary *_data;
    OAAppSettings *_settings;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    OAMapPanelViewController *_mapPanel;
    OsmAndAppInstance _app;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"map_settings_appearance");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _settings = [OAAppSettings sharedManager];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupView];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_mapPanel recreateControls];
    [_mapPanel refreshMap:YES];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupView
{
    _data = [NSMutableDictionary dictionary];
    _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    _mapPanel = [OARootViewController instance].mapPanel;
    
    NSMutableArray *activeMarkersArr = [NSMutableArray array];
    NSMutableArray *distanceIndicationArr = [NSMutableArray array];
    NSMutableArray *appearanceOnMapArr = [NSMutableArray array];

    [activeMarkersArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kActiveMarkers,
                        @"key" : kOneActiveMarker,
                        @"title" : OALocalizedString(@"one"),
                        @"img" : [self drawDeviceImage:@"ic_custom_direction_topbar_one" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_inactive" : [self drawDeviceImage:@"ic_custom_direction_topbar_one" bgColor:UIColorFromRGB(color_tint_gray)]
                        }];
    
    [activeMarkersArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kActiveMarkers,
                        @"key" : kTwoActiveMarkers,
                        @"title" : OALocalizedString(@"two"),
                        @"img" : [self drawDeviceImage:@"ic_custom_direction_topbar_two" bgColor:UIColorFromRGB(color_chart_orange)],
                        @"img_inactive" : [self drawDeviceImage:@"ic_custom_direction_topbar_two"  bgColor:UIColorFromRGB(color_tint_gray)]
                        }];

    [distanceIndicationArr addObject:@{
                        @"type" : [OASettingSwitchCell getCellIdentifier],
                        @"key" : kDistanceIndication,
                        @"value" : @([_settings.distanceIndicationVisibility get]),
                        @"title" : OALocalizedString(@"distance_indication"),
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
                        @"type" : [OASettingSwitchCell getCellIdentifier],
                        @"key" : kArrowsOnMap,
                        @"value" : @([_settings.arrowsOnMap get]),
                        @"title" : OALocalizedString(@"arrows_on_map"),
                        }];
    
    [appearanceOnMapArr addObject:@{
                        @"type" : [OASettingSwitchCell getCellIdentifier],
                        @"key" : kLinesOnMap,
                        @"value" : @([_settings.directionLines get]),
                        @"title" : OALocalizedString(@"direction_lines"),
                        }];
 
    _data = @{ @"appearanceOnMap" : appearanceOnMapArr,
               @"distanceIndication" : distanceIndicationArr,
               @"activeMarkers" : activeMarkersArr
            };
}

 - (void) adjustViews
 {
     CGRect buttonFrame = _backButton.frame;
     CGRect titleFrame = _titleView.frame;
     CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
     buttonFrame.origin.y = statusBarHeight;
     titleFrame.origin.y = statusBarHeight;
     _backButton.frame = buttonFrame;
     _titleView.frame = titleFrame;
 }

- (UIImage *) drawDeviceImage:(NSString *)fgImage bgColor:(UIColor *)bgColor
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


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
   return _data.count;;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![_settings.distanceIndicationVisibility get] && section == 1)
        return 1;
    return [_data[_data.allKeys[section]] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OASettingsCheckmarkCell getCellIdentifier]])
    {
        OASettingsCheckmarkCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsCheckmarkCell getCellIdentifier]];
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
            cell.iconImageView.image = selected ? item[@"img"] : item[@"img_inactive"];
        }
        else if ([key isEqualToString:kTwoActiveMarkers])
        {
            selected = activeMarkers == TWO_ACTIVE_MARKERS;
            cell.iconImageView.image = selected ? item[@"img"] : item[@"img_inactive"];
        }
        else if ([key isEqualToString:kTopBarDisplay])
        {
            selected = distanceIndication == TOP_BAR_DISPLAY;
            if (activeMarkers == ONE_ACTIVE_MARKER)
                cell.iconImageView.image = selected ? item[@"img_one"] : item[@"img_one_inactive"];
            else
                cell.iconImageView.image = selected ? item[@"img_two"] : item[@"img_two_inactive"];
        }
        else if ([key isEqualToString:kWidgetDisplay])
        {
            selected = distanceIndication == WIDGET_DISPLAY;
            if (activeMarkers == ONE_ACTIVE_MARKER)
                cell.iconImageView.image = selected ? item[@"img_one"] : item[@"img_one_inactive"];
            else
                cell.iconImageView.image = selected ? item[@"img_two"] : item[@"img_two_inactive"];
        }
        cell.titleLabel.text = item[@"title"];
        cell.checkmarkImageView.hidden = !selected;
        return cell;
    }
    else
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textView.text = item[@"title"];
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

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getTitleForHeaderSection:section];
    return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getTitleForHeaderSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    if (!title)
    {
        vw.label.text = title;
        return vw;
    }
    vw.label.text = [title upperCase];
    return vw;
}

- (NSString *) getTitleForHeaderSection:(NSInteger) section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"active_markers");
        case 1:
            return OALocalizedString(@"distance_indication");
        case 2:
            return OALocalizedString(@"appearance_on_map");
        default:
            return @"";
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *title = [self getTitleForFooterSection:section];
    return [OATableViewCustomFooterView getHeight:title width:tableView.bounds.size.width];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *title = [self getTitleForFooterSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    vw.label.text = title;
    return vw;
}

- (NSString *) getTitleForFooterSection:(NSInteger)section
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

- (void) setWidgetVisibility:(BOOL)visible collapsed:(BOOL)collapsed
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

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

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
        [tableView reloadRowsAtIndexPaths:[[NSMutableArray alloc] initWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1], nil] withRowAnimation:UITableViewRowAnimationFade];
    else
        [tableView reloadRowsAtIndexPaths:[[NSMutableArray alloc] initWithObjects:[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0], nil] withRowAnimation:UITableViewRowAnimationFade];
}

- (void) showDistanceIndication:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings.distanceIndicationVisibility set:switchView.isOn];
    [self setupView];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) showArrowsOnMap:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings.arrowsOnMap set:switchView.isOn];
}

- (void) showLinesOnMap:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
        [_settings.directionLines set:switchView.isOn];
}

@end
