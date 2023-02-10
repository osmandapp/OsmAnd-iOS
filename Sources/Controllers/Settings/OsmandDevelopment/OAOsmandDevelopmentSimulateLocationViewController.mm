//
//  OAOsmandDevelopmentSimulateLocationViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentSimulateLocationViewController.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAGPXDocument.h"
#import "Localization.h"
#import "OAColors.h"
#import "OALocationSimulation.h"
#import "OARootViewController.h"
#import "OARouteProvider.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapActions.h"
#import "OAOpenAddTrackViewController.h"
#import "OAOsmandDevelopmentSimulateSpeedSelectorViewController.h"
#import "OAIconTitleValueCell.h"
#import "OATitleRightIconCell.h"
#import "OAAutoObserverProxy.h"

@interface OAOsmandDevelopmentSimulateLocationViewController () <OAOpenAddTrackDelegate, OAOsmandDevelopmentSimulateSpeedSelectorDelegate>

@end

@implementation OAOsmandDevelopmentSimulateLocationViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAAutoObserverProxy* _simulateRoutingObserver;
    NSArray<NSArray *> *_data;
    NSString *_headerDescription;
    NSString *_selectedTrackName;
    EOASimulateNavigationSpeed _selectedSpeedMode;
}

NSString *const kTrackSelectKey = @"kTrackSelectKey";
NSString *const kMovementSpeedKey = @"kMovementSpeedKey";
NSString *const kStartStopButtonKey = @"kStartStopButtonKey";

#pragma mark - Initialization

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _selectedTrackName = _settings.simulateNavigationGpxTrack;
    _selectedSpeedMode = [OASimulateNavigationSpeed fromKey:_settings.simulateNavigationGpxTrackSpeedMode];
    _simulateRoutingObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onTrackAnimationFinished) andObserve:_app.simulateRoutingObservable];

    _headerDescription = OALocalizedString(@"simulate_your_location_gpx_descr");
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:[UIFont scaledSystemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];

    self.titleLabel.textColor = UIColor.whiteColor;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_simulateLocationDelegate)
        [_simulateLocationDelegate onSimulateLocationInformationUpdated];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"simulate_your_location");
}

- (UIColor *)getNavbarColor
{
    return UIColorFromRGB(color_navbar_orange);
}

- (UIColor *)getNavbarButtonsTintColor
{
    return UIColor.whiteColor;
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (BOOL)isNavbarBlurring
{
    return NO;
}

#pragma mark - Table data

- (void) generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    BOOL isGpxTrackSelected = _selectedTrackName && _selectedTrackName.length > 0;
    BOOL isRouteAnimating = [_app.locationServices.locationSimulation isRouteAnimating];
    
    NSMutableArray *settingsSection = [NSMutableArray array];
    NSString *trackNameText;
    if (isGpxTrackSelected)
        trackNameText = [[_selectedTrackName lastPathComponent] stringByDeletingPathExtension];
    else
        trackNameText = OALocalizedString(@"gpx_select_track");
    [settingsSection addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"key" : kTrackSelectKey,
        @"titleText" : OALocalizedString(@"shared_string_gpx_track"),
        @"titleColor" : isRouteAnimating ? UIColorFromRGB(color_text_footer) : UIColor.blackColor,
        @"descText" : trackNameText,
        @"descColor" : UIColorFromRGB(color_text_footer),
        @"icon" : @"ic_custom_trip",
        @"iconColor" : isRouteAnimating ? UIColorFromRGB(color_text_footer) : UIColorFromRGB(color_primary_purple),
        @"actionBlock" : (^void(){ [self openGpxTrackSelector]; }),
        @"isActionEnabled" : @(!isRouteAnimating),
        @"headerTitle" : @" ",
        @"footerTitle" : OALocalizedString(@"simulate_location_track_select_descr"),
    }];
    
    BOOL isMovementSpeedButtonActive = !isRouteAnimating && isGpxTrackSelected;
    [settingsSection addObject:@{
        @"type" : [OAIconTitleValueCell getCellIdentifier],
        @"key" : kMovementSpeedKey,
        @"titleText" : OALocalizedString(@"simulate_location_movement_speed"),
        @"titleColor" : isMovementSpeedButtonActive ? UIColor.blackColor : UIColorFromRGB(color_text_footer),
        @"descText" : [OASimulateNavigationSpeed toTitle:_selectedSpeedMode],
        @"descColor" : UIColorFromRGB(color_text_footer),
        @"icon" : @"ic_action_max_speed",
        @"iconColor" : isMovementSpeedButtonActive ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer),
        @"actionBlock" : (^void(){ [self openMovementSpeedSelector]; }),
        @"isActionEnabled" : @(isMovementSpeedButtonActive),
    }];
    [tableData addObject:settingsSection];
    
    NSMutableArray *actionsSection = [NSMutableArray array];
    NSString *buttonSectionFooter = @"";
    if (!isGpxTrackSelected)
        buttonSectionFooter = OALocalizedString(@"simulate_location_unselected_track_footer");
    else if (isRouteAnimating)
        buttonSectionFooter = OALocalizedString(@"simulate_in_progress");
    [actionsSection addObject:@{
        @"type" : [OATitleRightIconCell getCellIdentifier],
        @"key" : kStartStopButtonKey,
        @"titleText" : isRouteAnimating ? OALocalizedString(@"shared_string_control_stop") : OALocalizedString(@"shared_string_control_start"),
        @"icon" : isRouteAnimating ? @"ic_custom_stop" : @"ic_custom_play",
        @"color" : isGpxTrackSelected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer),
        @"actionBlock" : (^void(){ [self setTrackAnimationEnabled:!isRouteAnimating]; }),
        @"isActionEnabled" : @(isGpxTrackSelected),
        @"headerTitle" : @" ",
        @"footerTitle" : buttonSectionFooter,
    }];
    [tableData addObject:actionsSection];
    
    _data = [NSArray arrayWithArray:tableData];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) reloadData
{
    [self generateData];
    [self.tableView reloadData];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:0 inSection:section]];
    return item[@"headerTitle"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:0 inSection:section]];
    return item[@"footerTitle"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.textView.text = item[@"titleText"];
            cell.textView.textColor = item[@"titleColor"];
            cell.descriptionView.text = item[@"descText"];
            cell.descriptionView.textColor = item[@"descColor"];
            cell.leftIconView.tintColor = item[@"iconColor"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"titleText"];
        cell.titleView.textColor = item[@"color"];
        cell.iconView.tintColor = item[@"color"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"icon"]]];
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = [self getItem:indexPath];
    BOOL isActionEnabled = [item[@"isActionEnabled"] boolValue];
    void (^actionBlock)() = item[@"actionBlock"];
    if (actionBlock && isActionEnabled)
        actionBlock();
}

#pragma mark - Selectors

- (void)onRotation
{
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:[UIFont scaledSystemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) openGpxTrackSelector
{
    OAOpenAddTrackViewController *vc = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOASelectTrack showCurrent:YES];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void) openMovementSpeedSelector
{
    OAOsmandDevelopmentSimulateSpeedSelectorViewController *vc = [[OAOsmandDevelopmentSimulateSpeedSelectorViewController alloc] init];
    vc.speedSelectorDelegate = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void) setTrackAnimationEnabled:(BOOL)isEnabled
{
    if (isEnabled)
    {
        NSInteger speedup = ((NSInteger)_selectedSpeedMode) + 1;
        NSString * fullPath = [_app.gpxPath stringByAppendingPathComponent:_selectedTrackName];
        OAGPXDocument *gpxDocument = [[OAGPXDocument alloc] initWithGpxFile:fullPath];
        OAGPXRouteParamsBuilder *gpxParamsBuilder = [[OAGPXRouteParamsBuilder alloc] initWithDoc:gpxDocument];
        [_app.locationServices.locationSimulation startAnimationThread:[gpxParamsBuilder getSimulatedLocations] useLocationTime:NO coeff:speedup];
    }
    else
    {
        [_app.locationServices.locationSimulation startStopRouteAnimation];
    }
    [self reloadData];
}

- (void) onTrackAnimationFinished
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

#pragma mark - OAOpenAddTrackDelegate

- (void) onFileSelected:(NSString *)gpxFilePath
{
    _settings.simulateNavigationGpxTrack = gpxFilePath;
    _selectedTrackName = gpxFilePath;
    [self reloadData];
}


#pragma mark - OAOsmandDevelopmentSimulateSpeedSelectorDelegate

- (void) onSpeedSelectorInformationUpdated:(EOASimulateNavigationSpeed)selectedSpeedMode;
{
    _settings.simulateNavigationGpxTrackSpeedMode = [OASimulateNavigationSpeed toKey:selectedSpeedMode];
    _selectedSpeedMode = selectedSpeedMode;
    [self reloadData];
}

@end
