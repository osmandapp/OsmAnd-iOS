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
    _titleView.text = OALocalizedString(@"appearance");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _settings = [OAAppSettings sharedManager];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
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

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupView
{
    
    [self applySafeAreaMargins];
    [self adjustViews];
    
    _data = [NSMutableDictionary dictionary];
    _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    _mapPanel = [OARootViewController instance].mapPanel;
    
    NSMutableArray *activeMarkersArr = [NSMutableArray array];
    NSMutableArray *distanceIndicationArr = [NSMutableArray array];
    NSMutableArray *appearanceOnMapArr = [NSMutableArray array];

    [activeMarkersArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"section" : kActiveMarkers,
                        @"key" : kOneActiveMarker,
                        @"title" : OALocalizedString(@"one"),
                        @"fg_img" : @"ic_custom_direction_topbar_one.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_chart_orange)
                        }];
    
    [activeMarkersArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"section" : kActiveMarkers,
                        @"key" : kTwoActiveMarkers,
                        @"title" : OALocalizedString(@"two"),
                        @"fg_img" : @"ic_custom_direction_topbar_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_tint_gray)
                        }];

    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"key" : kDistanceIndication,
                        @"title" : OALocalizedString(@"distance_indication"),
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"section" : kDistanceIndication,
                        @"key" : kTopBarDisplay,
                        @"title" : OALocalizedString(@"shared_string_topbar"),
                        @"fg_img" : @"ic_custom_direction_topbar_one.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_chart_orange)
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"section" : kDistanceIndication,
                        @"key" : kWidgetDisplay,
                        @"title" : OALocalizedString(@"shared_string_widgets"),
                        @"fg_img" : @"ic_custom_direction_widget_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_tint_gray)
                        }];
   
    [appearanceOnMapArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"key" : kArrowsOnMap,
                        @"title" : OALocalizedString(@"arrows_on_map"),
                        }];
    
    [appearanceOnMapArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"key" : kLinesOnMap,
                        @"title" : OALocalizedString(@"direction_lines"),
                        }];
 
    _data = @{ @"appearanceOnMap" : appearanceOnMapArr,
               @"distanceIndication" : distanceIndicationArr,
               @"activeMarkers" : activeMarkersArr
            };
  
    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
   
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
     [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
     [fgColor setFill];
     [fgImage drawInRect:CGRectMake( 0.0, 0.0, fgImage.size.width, fgImage.size.height)];
     
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
    if (![_settings.distanceIndication get] && section == 1)
        return 1;
    return [_data[_data.allKeys[section]] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OASettingsCheckmarkCell"])
    {
        static NSString* const identifierCell = @"OASettingsCheckmarkCell";
        OASettingsCheckmarkCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCheckmarkCell" owner:self options:nil];
            cell = (OASettingsCheckmarkCell *)[nib objectAtIndex:0];
            
            cell.separatorInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, CGFLOAT_MAX);
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(50, cell.contentView.frame.size.height - 0.5, cell.contentView.frame.size.width, 1)];
            separator.backgroundColor = UIColorFromRGB(color_tint_gray);
            [cell.contentView addSubview:separator];
        }
        
        UIImage *fgImage = [[UIImage imageNamed:item[@"fg_img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *bgImage = [[UIImage imageNamed:item[@"bg_img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        cell.iconImageView.image = [self drawImage:fgImage inImage:bgImage bgColor:item[@"bg_color"] fgColor:item[@"fg_color"]];
        cell.titleLabel.text = item[@"title"];
        
        cell.checkmarkImageView.hidden = ![item[@"value"] boolValue];
        
        if ([item[@"key"] isEqualToString:kOneActiveMarker])
            cell.checkmarkImageView.hidden = ![_settings.oneActiveMarker get];
        if ([item[@"key"] isEqualToString:kTwoActiveMarkers])
            cell.checkmarkImageView.hidden = ![_settings.twoActiveMarker get];
        if ([item[@"key"] isEqualToString:kTopBarDisplay])
            cell.checkmarkImageView.hidden = ![_settings.topBarDisplay get];
        if ([item[@"key"] isEqualToString:kWidgetDisplay])
            cell.checkmarkImageView.hidden = ![_settings.widgetDisplay get];
        
        [cell.checkmarkImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.checkmarkImageView.tintColor = UIColorFromRGB(color_primary_purple);
        
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
        }
        
        cell.textView.text = item[@"title"];
        cell.descriptionView.hidden = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if ([item[@"key"] isEqualToString:kDistanceIndication])
        {
            [cell.switchView setOn:[_settings.distanceIndication get]];
            [cell.switchView addTarget:self action:@selector(showDistanceIndication:) forControlEvents:UIControlEventValueChanged];
        }
        if ([item[@"key"] isEqualToString:kArrowsOnMap])
        {
            [cell.switchView setOn:[_settings.arrowsOnMap get]];
            [cell.switchView addTarget:self action:@selector(showArrowsOnMap:) forControlEvents:UIControlEventValueChanged];
        }
        if ([item[@"key"] isEqualToString:kLinesOnMap])
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
    if (marker2nd && [_settings.twoActiveMarker get])
        [_mapWidgetRegistry setVisibility:marker2nd visible:visible collapsed:collapsed];
    else
        [_mapWidgetRegistry setVisibility:marker2nd visible:NO collapsed:collapsed];
    [[OARootViewController instance].mapPanel recreateControls];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    
    if ([item[@"section"] isEqualToString:@"activeMarkers"])
    {
        if (indexPath.row == 0)
        {
            [_settings.oneActiveMarker set:YES];
            [_settings.twoActiveMarker set:NO];
        }
        else
        {
            [_settings.oneActiveMarker set:NO];
            [_settings.twoActiveMarker set:YES];
        }
        if ([_settings.widgetDisplay get])
            [self setWidgetVisibility:YES collapsed:NO];
    }
    if ([item[@"section"] isEqualToString:@"distanceIndication"])
    {
        if (indexPath.row == 1)
        {
            [_settings.topBarDisplay set:YES];
            [_settings.widgetDisplay set:NO];
            [self setWidgetVisibility:NO collapsed:NO];
        }
        else
        {
            [_settings.topBarDisplay set:NO];
            [_settings.widgetDisplay set:YES];
            [self setWidgetVisibility:YES collapsed:NO];
        }
    }
    [self.tableView reloadData];
}

- (void) showDistanceIndication:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        [_settings.distanceIndication set:switchView.isOn];
        if (![_settings.distanceIndication get])
        {
            [_settings.lastPositionWidgetDisplay set:[_settings.widgetDisplay get]];
            [_settings.topBarDisplay set:NO];
            [_settings.widgetDisplay set:NO];
        }
        else
        {
            if ([_settings.lastPositionWidgetDisplay get])
                [_settings.widgetDisplay set:YES];
            else
                [_settings.topBarDisplay set:YES];
        }
    }
    [self.tableView reloadData];
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
