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
#import "OsmAnd_Maps-Swift.h"
#import "OALocationSimulation.h"
#import "OARootViewController.h"
#import "OARouteProvider.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapActions.h"
#import "OAOpenAddTrackViewController.h"
#import "OAOsmandDevelopmentSimulateSpeedSelectorViewController.h"
#import "OAValueTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAAutoObserverProxy.h"
#import "GeneratedAssetSymbols.h"

@interface OAOsmandDevelopmentSimulateLocationViewController () <OAOpenAddTrackDelegate, OAOsmandDevelopmentSimulateSpeedSelectorDelegate>

@end

@implementation OAOsmandDevelopmentSimulateLocationViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
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
    _headerDescription = OALocalizedString(@"simulate_your_location_gpx_descr");
}

- (void)registerObservers
{
    [self addObserver:[[OAAutoObserverProxy alloc] initWith:self
                                                withHandler:@selector(onTrackAnimationFinished)
                                                 andObserve:_app.simulateRoutingObservable]];
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:kHeaderDescriptionFont textColor:[UIColor colorNamed:ACColorNameTextColorSecondary] isBigTitle:NO parentViewWidth:self.view.frame.size.width];
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

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
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
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"key" : kTrackSelectKey,
        @"titleText" : OALocalizedString(@"shared_string_gpx_track"),
        @"titleColor" : isRouteAnimating ? [UIColor colorNamed:ACColorNameTextColorSecondary] : [UIColor colorNamed:ACColorNameTextColorPrimary],
        @"descText" : trackNameText,
        @"descColor" : [UIColor colorNamed:ACColorNameTextColorSecondary],
        @"icon" : @"ic_custom_trip",
        @"iconColor" : isRouteAnimating ? [UIColor colorNamed:ACColorNameIconColorDisabled] : [UIColor colorNamed:ACColorNameIconColorActive],
        @"actionBlock" : (^void(){ [self openGpxTrackSelector]; }),
        @"isActionEnabled" : @(!isRouteAnimating),
        @"headerTitle" : @" ",
        @"footerTitle" : OALocalizedString(@"simulate_location_track_select_descr"),
    }];
    
    BOOL isMovementSpeedButtonActive = !isRouteAnimating && isGpxTrackSelected;
    [settingsSection addObject:@{
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"key" : kMovementSpeedKey,
        @"titleText" : OALocalizedString(@"simulate_location_movement_speed"),
        @"titleColor" : isMovementSpeedButtonActive ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary],
        @"descText" : [OASimulateNavigationSpeed toTitle:_selectedSpeedMode],
        @"descColor" : [UIColor colorNamed:ACColorNameTextColorSecondary],
        @"icon" : @"ic_action_max_speed",
        @"iconColor" : isMovementSpeedButtonActive ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled],
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
        @"type" : [OARightIconTableViewCell getCellIdentifier],
        @"key" : kStartStopButtonKey,
        @"titleText" : isRouteAnimating ? OALocalizedString(@"shared_string_control_stop") : OALocalizedString(@"shared_string_control_start"),
        @"icon" : isRouteAnimating ? @"ic_custom_stop" : @"ic_custom_play",
        @"color" : isGpxTrackSelected ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled],
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
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"titleText"];
            cell.titleLabel.textColor = item[@"titleColor"];
            cell.valueLabel.text = item[@"descText"];
            cell.valueLabel.textColor = item[@"descColor"];
            cell.leftIconView.tintColor = item[@"iconColor"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"titleText"];
            cell.titleLabel.textColor = item[@"color"];
            cell.rightIconView.tintColor = item[@"color"];
            [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"icon"]]];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
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
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:kHeaderDescriptionFont textColor:[UIColor colorNamed:ACColorNameTextColorSecondary] isBigTitle:NO parentViewWidth:self.view.frame.size.width];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) openGpxTrackSelector
{
    OAOpenAddTrackViewController *vc = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOASelectTrack showCurrent:YES];
    vc.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void) openMovementSpeedSelector
{
    OAOsmandDevelopmentSimulateSpeedSelectorViewController *vc = [[OAOsmandDevelopmentSimulateSpeedSelectorViewController alloc] init];
    vc.speedSelectorDelegate = self;
    [self showModalViewController:vc];
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
