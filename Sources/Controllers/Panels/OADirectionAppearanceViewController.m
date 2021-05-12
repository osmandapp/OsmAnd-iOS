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

#define kHeaderId @"TableViewSectionHeader"
#define kFooterId @"TableViewSectionFooter"
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
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
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
    
    EOAActiveMarkerConstant activeMarkers = [_settings.activeMarkers get];
    EOADistanceIndicationConstant distanceIndication = [_settings.distanceIndication get];

    [activeMarkersArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kActiveMarkers,
                        @"key" : kOneActiveMarker,
                        @"value" : activeMarkers == ONE_ACTIVE_MARKER ? @YES : @NO,
                        @"title" : OALocalizedString(@"one"),
                        @"fg_img" : @"ic_custom_direction_topbar_one.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : activeMarkers == ONE_ACTIVE_MARKER ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray)
                        }];
    
    [activeMarkersArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kActiveMarkers,
                        @"key" : kTwoActiveMarkers,
                        @"value" : activeMarkers == TWO_ACTIVE_MARKERS ? @YES : @NO,
                        @"title" : OALocalizedString(@"two"),
                        @"fg_img" : @"ic_custom_direction_topbar_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : activeMarkers == TWO_ACTIVE_MARKERS ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray)
                        }];

    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"key" : kDistanceIndication,
                        @"value" : @([_settings.distanceIndicationVisibility get]),
                        @"title" : OALocalizedString(@"distance_indication"),
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kDistanceIndication,
                        @"key" : kTopBarDisplay,
                        @"value" : distanceIndication == TOP_BAR_DISPLAY ? @YES : @NO,
                        @"title" : OALocalizedString(@"shared_string_topbar"),
                        @"fg_img" : activeMarkers == ONE_ACTIVE_MARKER ? @"ic_custom_direction_topbar_one.png" : @"ic_custom_direction_topbar_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : distanceIndication == TOP_BAR_DISPLAY ? UIColorFromRGB(color_chart_orange) :
                            UIColorFromRGB(color_tint_gray)
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : [OASettingsCheckmarkCell getCellIdentifier],
                        @"section" : kDistanceIndication,
                        @"key" : kWidgetDisplay,
                        @"value" : distanceIndication == WIDGET_DISPLAY ? @YES : @NO,
                        @"title" : OALocalizedString(@"shared_string_widgets"),
                        @"fg_img" : activeMarkers == ONE_ACTIVE_MARKER ? @"ic_custom_direction_widget_one.png" : @"ic_custom_direction_widget_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : distanceIndication == WIDGET_DISPLAY ? UIColorFromRGB(color_chart_orange) :
                        UIColorFromRGB(color_tint_gray)
                        }];
   
    [appearanceOnMapArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"key" : kArrowsOnMap,
                        @"value" : @([_settings.arrowsOnMap get]),
                        @"title" : OALocalizedString(@"arrows_on_map"),
                        }];
    
    [appearanceOnMapArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
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

- (UIImage *) drawImage:(UIImage*) fgImage inImage:(UIImage*) bgImage bgColor:(UIColor *)bgColor fgColor:(UIColor *)fgColor
 {
     UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
     
     [bgColor setFill];
     [bgImage drawInRect:CGRectMake(0.0, 0.0, bgImage.size.width, bgImage.size.height)];
     [fgColor setFill];
     [fgImage drawInRect:CGRectMake(0.0, 0.0, fgImage.size.width, fgImage.size.height)];
     
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
        UIImage *fgImage = [[UIImage imageNamed:item[@"fg_img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *bgImage = [[UIImage imageNamed:item[@"bg_img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.image = [self drawImage:fgImage inImage:bgImage bgColor:item[@"bg_color"] fgColor:item[@"fg_color"]];
        cell.titleLabel.text = item[@"title"];
        cell.checkmarkImageView.hidden = ![item[@"value"] boolValue];
        return cell;
    }
    else
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
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
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
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
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kFooterId];
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
    [self setupView];
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
