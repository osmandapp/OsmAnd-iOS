//
//  OAConfigureMenuMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAConfigureMenuMainScreen.h"
#import "OAConfigureMenuViewController.h"
#import "Localization.h"
#import "OAAppModeCell.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OASettingSwitchCell.h"
#import "OASettingsTableViewCell.h"
#import "OAMapHudViewController.h"
#import "OAQuickActionHudViewController.h"
#import "OAQuickActionListViewController.h"
#import "OADirectionAppearanceViewController.h"
#import "OAColors.h"
#import "OAMapLayers.h"
#import "OAIAPHelper.h"
#import "OAWeatherPlugin.h"

@interface OAConfigureMenuMainScreen () <OAAppModeCellDelegate>

@end

@implementation OAConfigureMenuMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    
    OAAppModeCell *_appModeCell;
}

@synthesize configureMenuScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAConfigureMenuViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
        
        title = OALocalizedString(@"layer_map_appearance");
        configureMenuScreen = EConfigureMenuScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) setupView
{
    [self setupViewInternal];
    [tblView reloadData];
}

- (void) setupViewInternal
{
    NSMutableDictionary *sectionMapStyle = [NSMutableDictionary dictionary];
    [sectionMapStyle setObject:[OAAppModeCell getCellIdentifier] forKey:@"type"];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    NSDictionary *mapStyles = @{ @"groupName" : @"",
                                 @"cells" : @[sectionMapStyle]
                                 };
    [arr addObject:mapStyles];
    
    // Quick action
    NSArray *controls = @[@{
                              @"groupName" : @"",
                              @"cells" : @[@{ @"title" : OALocalizedString(@"quick_action_name"),
                                            @"description" : @"",
                                            @"key" : @"quick_action",
                                            @"img" : @"ic_custom_quick_action",
                                            @"selected" : @([_settings.quickActionIsOn get]),
                                            @"secondaryImg" : @"ic_action_additional_option",
                                            @"type" : [OASettingSwitchCell getCellIdentifier]}]
                            }];
    [arr addObjectsFromArray:controls];
    
    // Right panel
    NSMutableArray *controlsList = [NSMutableArray array];
    controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_right"),
                     @"cells" : controlsList,
                     } ];
    
    [self addControls:controlsList widgets:[_mapWidgetRegistry getRightWidgetSet] mode:_settings.applicationMode.get];
    
    if (controlsList.count > 0)
        [arr addObjectsFromArray:controls];
    
    // Left panel
    controlsList = [NSMutableArray array];
    controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_left"),
                     @"cells" : controlsList,
                     } ];
    
    [self addControls:controlsList widgets:[_mapWidgetRegistry getLeftWidgetSet] mode:_settings.applicationMode.get];
    
    if (controlsList.count > 0)
        [arr addObjectsFromArray:controls];
    
    // Others
    controlsList = [NSMutableArray array];
    controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_appearance_rem"),
                     @"cells" : controlsList,
                     } ];
    
    if (_settings.applicationMode.get != OAApplicationMode.DEFAULT)
    {
        [controlsList addObject:@{ @"title" : OALocalizedString(@"osm_str_name"),
                                   @"key" : @"street_name",
                                   @"selected" : @([_settings.showStreetName get]),
                                   @"type" : [OASettingSwitchCell getCellIdentifier]} ];
    }
    
    [controlsList addObject:@{ @"title" : OALocalizedString(@"coordinates_widget"),
                               @"img" : @"ic_custom_coordinates",
                               @"key" : @"coordinates_widget",
                               @"selected" : @([_settings.showCoordinatesWidget get]),
                               @"type" : [OASettingSwitchCell getCellIdentifier]} ];
    
    [controlsList addObject:@{ @"title" : OALocalizedString(@"map_widget_distance_by_tap"),
                               @"img" : @"ic_action_ruler_line",
                               @"key" : @"map_widget_distance_by_tap",
                               @"selected" : @([_settings.showDistanceRuler get]),
                               @"type" : [OASettingSwitchCell getCellIdentifier]} ];
    
    EOADistanceIndicationConstant distanceIndication = [_settings.distanceIndication get];
    NSString *markersAppeareance = distanceIndication == WIDGET_DISPLAY ? OALocalizedString(@"shared_string_widgets") : OALocalizedString(@"shared_string_topbar") ;
    [controlsList addObject:@{ @"type" : [OASettingsTableViewCell getCellIdentifier],
                               @"title" : OALocalizedString(@"map_markers"),
                               @"value" : markersAppeareance,
                               @"key" : @"map_markers"}];
    
    [controlsList addObject:@{ @"title" : OALocalizedString(@"map_widget_transparent"),
                               @"key" : @"map_widget_transparent",
                               @"selected" : @([_settings.transparentMapTheme get]),
                               @"type" : [OASettingSwitchCell getCellIdentifier]} ];
    
    [controlsList addObject:@{ @"title" : OALocalizedString(@"show_lanes"),
                               @"key" : @"show_lanes",
                               @"selected" : @([_settings.showLanes get]),
    
                               @"type" : [OASettingSwitchCell getCellIdentifier]} ];
    if (controlsList.count > 0)
        [arr addObjectsFromArray:controls];
    
    tableData = [NSArray arrayWithArray:arr];
}

- (void) addControls:(NSMutableArray *)controlsList widgets:(NSOrderedSet<OAMapWidgetRegInfo *> *)widgets mode:(OAApplicationMode *)mode
{
    for (OAMapWidgetRegInfo *r in widgets)
    {
        if (![mode isWidgetAvailable:r.key])
            continue;

        BOOL selected = [r visibleCollapsed:mode] || [r visible:mode];
        NSString *collapsedStr = OALocalizedString(@"shared_string_collapse");
        
        [controlsList addObject:@{ @"title" : [r getMessage],
                                   @"description" : [r visibleCollapsed:mode] ? collapsedStr : @"",
                                   @"key" : r.key,
                                   @"img" : [r getImageId],
                                   @"selected" : @(selected),
                                   @"secondaryImg" : r.widget ? @"ic_action_additional_option" : @"",
                                   
                                   @"type" : [OASettingSwitchCell getCellIdentifier]} ];
    }
}

- (BOOL) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    NSString *key = data[@"key"];
    
    OASettingSwitchCell *cell = [self.tblView cellForRowAtIndexPath:indexPath];
    cell.imgView.tintColor = sw.on ? UIColorFromRGB(_settings.applicationMode.get.getIconColor) : UIColorFromRGB(color_icon_inactive);
    
    if ([key isEqualToString:@"quick_action"])
    {
        [_settings.quickActionIsOn set:sw.on];
        [[OARootViewController instance].mapPanel.hudViewController.quickActionController updateViewVisibility];
        return YES;
    }
    
    [self setVisibility:indexPath visible:sw.on collapsed:NO];
    OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:key];
    if (r && r.widget)
        [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    return NO;
}

- (void) setVisibility:(NSIndexPath *)indexPath visible:(BOOL)visible collapsed:(BOOL)collapsed
{
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    NSString *key = data[@"key"];
    if (key)
    {
        OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:key];
        if (r)
        {
            [_mapWidgetRegistry setVisibility:r visible:visible collapsed:collapsed];
            [[OARootViewController instance].mapPanel recreateControls];
        }
        else if ([key isEqualToString:@"coordinates_widget"])
        {
            [_settings.showCoordinatesWidget set:visible];
            [[[OsmAndApp instance].data mapLayerChangeObservable] notifyEvent];
        }
        else if ([key isEqualToString:@"street_name"])
        {
            [_settings.showStreetName set:visible];
            [[OARootViewController instance].mapPanel recreateControls];
        }
        else if ([key isEqualToString:@"map_widget_distance_by_tap"])
        {
            [_settings.showDistanceRuler set:visible];
            [[OARootViewController instance].mapPanel.mapViewController.mapLayers.rulerByTapControlLayer updateLayer];
        }
        else if ([key isEqualToString:@"map_widget_transparent"])
        {
            [_settings.transparentMapTheme set:visible];
        }
        else if ([key isEqualToString:@"show_lanes"])
        {
            [_settings.showLanes set:visible];
        }
        [self setupViewInternal];
    }
}

- (CGFloat) heightForHeader:(NSInteger)section
{
    NSDictionary* data = tableData[section][@"cells"][0];
    if ([data[@"key"] isEqualToString:@"quick_action"])
        return 10.0;
    else if ([data[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
        return 0;
    else
        return 34.0;
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
    [_settings setApplicationModePref:mode];
    [self setupView];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return tableData.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return tableData[section][@"groupName"];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData[section][@"cells"] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([data[@"type"] isEqualToString:[OAAppModeCell getCellIdentifier]])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAAppModeCell getCellIdentifier] owner:self options:nil];
            _appModeCell = (OAAppModeCell *)[nib objectAtIndex:0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode.get;
            _appModeCell.delegate = self;
        }
        
        outCell = _appModeCell;
    }
    else if ([data[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [self updateSettingSwitchCell:cell data:data];
            
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = ((NSNumber *)data[@"selected"]).boolValue;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([data[@"type"] isEqualToString:[OASettingsTableViewCell getCellIdentifier]])
    {
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
            cell.descriptionView.font = [UIFont systemFontOfSize:17.0];
            cell.iconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = data[@"title"];
            cell.descriptionView.text = data[@"value"];
        }
        return cell;
    }
    
    return outCell;
}

- (void) updateSettingSwitchCell:(OASettingSwitchCell *)cell data:(NSDictionary *)data
{
    NSString *imgName = data[@"img"];
    if (imgName)
    {
        cell.imgView.image = [UIImage templateImageNamed:imgName];
        cell.imgView.tintColor = (((NSNumber *)data[@"selected"]).boolValue) ? UIColorFromRGB(_settings.applicationMode.get.getIconColor) : UIColorFromRGB(color_icon_inactive);
    }
    else
    {
        cell.imgView.image = nil;
    }
    
    cell.textView.text = data[@"title"];
    NSString *desc = data[@"description"];
    cell.descriptionView.text = desc;
    cell.descriptionView.hidden = desc.length == 0;
    NSString *secondaryImgName = data[@"secondaryImg"];
    [cell setSecondaryImage:secondaryImgName.length > 0 ? [UIImage imageNamed:data[@"secondaryImg"]] : nil];
    if ([cell needsUpdateConstraints])
        [cell setNeedsUpdateConstraints];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAConfigureMenuViewController *configureMenuViewController;
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    if ([data[@"key"] isEqualToString:@"quick_action"])
    {
        OAQuickActionListViewController *vc = [[OAQuickActionListViewController alloc] init];
        [self.vwController.navigationController pushViewController:vc animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    if ([data[@"key"] isEqualToString:@"map_markers"])
    {
        OADirectionAppearanceViewController *vc = [[OADirectionAppearanceViewController alloc] init];
        [self.vwController.navigationController pushViewController:vc animated:YES];
    }
    else if ([data[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:data[@"key"]];
        if (r && r.widget)
        {
            configureMenuViewController = [[OAConfigureMenuViewController alloc] initWithConfigureMenuScreen:EConfigureMenuScreenVisibility param:data[@"key"]];
        }
        else
        {
            OASettingSwitchCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            BOOL visible = !cell.switchView.isOn;
            [cell.switchView setOn:visible animated:YES];
            [self onSwitchClick:cell.switchView];
        }
    }
    
    if (configureMenuViewController)
        [configureMenuViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:configureMenuViewController == nil];
}

@end
