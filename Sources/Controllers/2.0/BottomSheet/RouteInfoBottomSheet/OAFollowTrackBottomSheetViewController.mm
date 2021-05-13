//
//  OAFollowTrackBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAFollowTrackBottomSheetViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OATitleIconRoundCell.h"
#import "Localization.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAGPXTrackCell.h"
#import "OAGPXDatabase.h"
#import "OASegmentTableViewCell.h"
#import "OAIconTextDescCell.h"
#import "OASettingSwitchCell.h"
#import "OATitleRightIconCell.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAGPXDocument.h"
#import "OARoutingHelper.h"
#import "OARoutePreferencesParameters.h"
#import "OARouteProvider.h"
#import "OAGPXMutableDocument.h"
#import "OARootViewController.h"
#import "OAMeasurementEditingContext.h"
#import "OAGpxData.h"
#import "OAGpxInfo.h"
#import "OAGPXUIHelper.h"
#import "OATargetPointsHelper.h"
#import "OAMapActions.h"

#define kGPXTrackCell @"OAGPXTrackCell"
#define kCellTypeTitleRightIcon @"OATitleRightIconCell"


@interface OAFollowTrackBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource, OAOpenAddTrackDelegate>

@end

@implementation OAFollowTrackBottomSheetViewController
{
    OAGpxTrkPt *_point;
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OAGPXDocument *_gpx;
    
    UITapGestureRecognizer *_buttonTapRecognizer;
    UILongPressGestureRecognizer *_buttonLongTapRecognizer;
    
    OALocalRoutingParameter *_passWholeRoute;
    OALocalRoutingParameter *_navigationType;
    
    OALocalRoutingParameter *_reverseParam;
    
    UINavigationController *_navigationController;
    
    BOOL _openGpxSelection;
}

- (instancetype) initWithFile:(OAGPXDocument *)gpx
{
    self = [super init];
    if (self)
    {
        if (gpx)
            _gpx = gpx;
        else
            _openGpxSelection = YES;
    }
    return self;
}

- (BOOL) animateShow
{
    return _gpx != nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[[UIImage imageNamed:@"ic_custom_arrow_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.closeButton removeFromSuperview];
    [self.headerDividerView removeFromSuperview];
    
    _buttonTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackArrowPressed:)];
    _buttonTapRecognizer.numberOfTapsRequired = 1;
    _buttonTapRecognizer.numberOfTouchesRequired = 1;
    
    _buttonLongTapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onBackArrowPressed:)];
    _buttonLongTapRecognizer.numberOfTouchesRequired = 1;
    
    [self.leftIconView addGestureRecognizer:_buttonTapRecognizer];
    [self.leftIconView addGestureRecognizer:_buttonLongTapRecognizer];
    self.leftIconView.userInteractionEnabled = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_openGpxSelection)
    {
        [self presentOpenTrackViewController:YES];
        _openGpxSelection = NO;
    }
}

- (void) setupGpxParmValues
{
    OAGPXRouteParamsBuilder *params = OARoutingHelper.sharedInstance.getCurrentGPXRoute;
    _passWholeRoute = [[OAOtherLocalRoutingParameter alloc] initWithId:gpx_option_from_start_point_id text:OALocalizedString(@"gpx_option_from_start_point") selected:params.passWholeRoute];
    _navigationType = [[OAOtherLocalRoutingParameter alloc] initWithId:gpx_option_calculate_first_last_segment_id text:OALocalizedString(@"gpx_option_calculate_first_last_segment") selected:params.calculateOsmAndRouteParts];
    
    _reverseParam = [[OAOtherLocalRoutingParameter alloc] initWithId:gpx_option_reverse_route_id text:OALocalizedString(@"gpx_option_reverse_route") selected:params.reverse];
}

- (void) applyLocalization
{
    self.titleView.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    self.titleView.text = OALocalizedString(@"follow_track");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (void) generateData
{
    [self setupGpxParmValues];
    
    NSMutableArray *data = [NSMutableArray new];
    NSString *fileName = nil;
    if (_gpx.path.length > 0)
        fileName = _gpx.path;
    else if (_gpx.tracks.count > 0)
        fileName = _gpx.tracks.firstObject.name;
    
    if (fileName == nil || fileName.length == 0)
        fileName = OALocalizedString(@"track");
    
    OAGPXRouteParamsBuilder *params = OARoutingHelper.sharedInstance.getCurrentGPXRoute;
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    OAGPX *gpxData = [db getGPXItem:[OAUtilities getGpxShortPath:fileName]];
    OsmAndAppInstance app = OsmAndApp.instance;
    
    NSString *title = [fileName.lastPathComponent stringByDeletingPathExtension];
    BOOL isSegment = _gpx.getNonEmptySegmentsCount > 1 && params != nil && params.selectedSegment != -1;
    if (isSegment)
    {
        title = [NSString stringWithFormat:@"%@, %@", [NSString stringWithFormat:OALocalizedString(@"some_of"), params.selectedSegment + 1, _gpx.getNonEmptySegmentsCount], title];
    }
    
    NSString *distance = gpxData ? [app getFormattedDistance:gpxData.totalDistance] : @"";
    NSString *time = gpxData ? [app getFormattedTimeInterval:gpxData.timeSpan shortFormat:YES] : @"";
    if (isSegment)
    {
        OAGpxTrkSeg *seg = params.selectedSegment < _gpx.getNonEmptySegmentsCount ? [_gpx getNonEmptyTrkSegments:NO][params.selectedSegment] : nil;
        if (seg)
        {
            distance = [app getFormattedDistance:[OAGPXUIHelper getSegmentDistance:seg]];
            time = [app getFormattedTimeInterval:[OAGPXUIHelper getSegmentTime:seg] shortFormat:YES];
        }
    }
    
    [data addObject:@[
        @{
            @"type" : kGPXTrackCell,
            @"title" : title,
            @"distance" : distance,
            @"time" : time,
            @"wpt" : gpxData && !isSegment ? [NSString stringWithFormat:@"%d", gpxData.wptPoints] : @"",
            @"key" : @"gpx_route"
        },
        @{
            @"type" : [OAIconTextDescCell getCellIdentifier],
            @"title" : OALocalizedString(@"select_another_track"),
            @"img" : @"ic_custom_folder",
            @"key" : @"select_another"
        },
        @{
            @"type" : [OASettingSwitchCell getCellIdentifier],
            @"title" : OALocalizedString(@"reverse_track_dir"),
            @"img" : @"ic_custom_swap",
            @"key" : @"reverse_track"
        },
        /*@{
            @"type" : [OAIconTextDescCell getCellIdentifier],
            @"title" : OALocalizedString(@"attach_to_the_roads"),
            @"img" : @"ic_custom_attach_track",
            @"key" : @"attach_to_roads"
        }*/
    ]];

    [data addObject:@[
        @{
            @"type" : kCellTypeTitleRightIcon,
            @"title" : OALocalizedString(@"point_to_navigate")
        },
        @{
            @"type" : [OASegmentTableViewCell getCellIdentifier],
            @"title0" : OALocalizedString(@"start_of_track"),
            @"title1" : OALocalizedString(@"nearest_point"),
            @"key" : @"point_to_start"
        },
        @{
            @"type" : kCellTypeTitleRightIcon,
            @"title" : OALocalizedString(@"nav_type_title")
        },
        @{
            @"type" : [OASegmentTableViewCell getCellIdentifier],
            @"title0" : OALocalizedString(@"nav_type_straight_line"),
            @"title1" : OARoutingHelper.sharedInstance.getAppMode.toHumanString,
            @"key" : @"nav_type"
        }
    ]];
    
    _data = data;
}

- (void) segmentChanged:(UISegmentedControl *)control
{
    NSInteger segmentIndex = control.tag;
    NSInteger selectedValue = control.selectedSegmentIndex;
    if (segmentIndex == 0)
    {
        BOOL shouldChange = (selectedValue == 0 && !_passWholeRoute.isSelected) || (selectedValue == 1 && _passWholeRoute.isSelected);
        if (shouldChange)
        {
            [_passWholeRoute applyNewParameterValue:!_passWholeRoute.isSelected];
        }
    }
    else if (segmentIndex == 1)
    {
        BOOL shouldChange = (selectedValue == 0 && _navigationType.isSelected) || (selectedValue == 1 && !_navigationType.isSelected);
        if (shouldChange)
        {
            [_navigationType applyNewParameterValue:!_navigationType.isSelected];
        }
    }
}

- (void) openPlanRoute
{
    if (_gpx)
    {
        OAGPXMutableDocument *mutableGpx = nil;
        if (_gpx.path && _gpx.path.length > 0)
            mutableGpx = [[OAGPXMutableDocument alloc] initWithGpxFile:_gpx.path];
        else if ([_gpx isKindOfClass:OAGPXMutableDocument.class])
            mutableGpx = (OAGPXMutableDocument *) _gpx;
        OAGpxData *gpxData = [[OAGpxData alloc] initWithFile:mutableGpx];
        OAMeasurementEditingContext *editingContext = [[OAMeasurementEditingContext alloc] init];
        editingContext.gpxData = gpxData;
        editingContext.appMode = OARoutingHelper.sharedInstance.getAppMode;
        editingContext.selectedSegment = OAAppSettings.sharedManager.gpxRouteSegment;
        [self dismissViewControllerAnimated:NO completion:^{
            [[OARootViewController instance].mapPanel closeRouteInfo];
            [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] initWithEditingContext:editingContext followTrackMode:YES]];
        }];
    }
}

- (UIColor *)getBackgroundColor
{
    return UIColor.clearColor;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OASegmentTableViewCell getCellIdentifier]])
    {
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, 20., 0, 0);
            
            cell.segmentControl.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1];
            
            if (@available(iOS 13.0, *))
                cell.segmentControl.selectedSegmentTintColor = UIColorFromRGB(color_primary_purple);
            else
                cell.segmentControl.tintColor = UIColorFromRGB(color_primary_purple);
            UIFont *font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
            [cell.segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor, NSFontAttributeName : font} forState:UIControlStateSelected];
            [cell.segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple), NSFontAttributeName : font} forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
            NSInteger paramIndex = indexPath.row == 1 ? 0 : 1;
            cell.segmentControl.tag = paramIndex;
            
            if (paramIndex == 0)
            {
                cell.segmentControl.selectedSegmentIndex = _passWholeRoute.isSelected ? 0 : 1;
            }
            else if (paramIndex == 1)
            {
                cell.segmentControl.selectedSegmentIndex = _navigationType.isSelected ? 1 : 0;
            }
        }
        return cell;
    }
    else if ([type isEqualToString:kGPXTrackCell])
    {
        static NSString* const identifierCell = kGPXTrackCell;
        OAGPXTrackCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kGPXTrackCell owner:self options:nil];
            cell = (OAGPXTrackCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsZero;
            [cell setRightButtonVisibility:YES];
            [cell.editButton addTarget:self action:@selector(openPlanRoute) forControlEvents:UIControlEventTouchUpInside];
            cell.editButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.distanceImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.timeImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.wptImageView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.distanceLabel.text = item[@"distance"];
            cell.timeLabel.text = item[@"time"];
            cell.wptLabel.text = item[@"wpt"];
            
            cell.distanceImageView.hidden = cell.distanceLabel.text.length == 0;
            cell.timeImageView.hidden = cell.timeLabel.text.length == 0;
            cell.wptImageView.hidden = cell.wptLabel.text.length == 0;
            
        }
        return cell;
    }
    else if ([type isEqualToString:[OAIconTextDescCell getCellIdentifier]])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
            cell.textView.lineBreakMode = NSLineBreakByWordWrapping;
            [cell.arrowIconView removeFromSuperview];
            [cell.iconView setTintColor:UIColorFromRGB(color_primary_purple)];
            cell.descView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
                
            [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else if ([type isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
            
            [cell setSecondaryImage:nil];
            
            cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);
        }
        
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.imgView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = UIColorFromRGB(color_primary_purple);
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = _reverseParam.isSelected;
            [_reverseParam setControlAction:cell.switchView];
            
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeTitleRightIcon])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:type];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:type owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            [cell setIconVisibility:NO];
            [cell setBottomOffset:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.001;
    else
    {
        return [OAUtilities calculateTextBounds:OALocalizedString(@"routing_settings") width:tableView.bounds.size.width font:[UIFont systemFontOfSize:13]].height + 38;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return OALocalizedString(@"routing_settings");
    return nil;
}

#pragma mark - UItableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row == 1 ? indexPath : nil;
}

- (void)presentOpenTrackViewController:(BOOL)animated
{
    _navigationController = [[UINavigationController alloc] init];
    _navigationController.navigationBarHidden = YES;
    OAOpenAddTrackViewController *saveTrackViewController = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOAFollowTrack];
    saveTrackViewController.delegate = self;
    [_navigationController setViewControllers:@[saveTrackViewController]];
    [self presentViewController:_navigationController animated:YES completion:nil];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"select_another"])
    {
        [self presentOpenTrackViewController:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    else if ([key isEqualToString:@"gpx_route"])
    {
        [self openPlanRoute];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITapGestureRecognizer

- (void) onBackArrowPressed:(UIGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            [UIView animateWithDuration:.1 animations:^{
                self.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            }];
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self onRightButtonPressed];
            break;
        }
        default:
            break;
    }
}

// MARK: OAOpenAddTrackDelegate

- (void)onFileSelected:(NSString *)gpxFilePath
{
    OAGPXDocument *document = OARoutingHelper.sharedInstance.getCurrentGPXRoute.file;
    [self setGpxRouteIfNeeded:document];
    
    [self generateData];
    [self.tableView reloadData];
    self.view.hidden = NO;
}

- (void)closeBottomSheet
{
    if (!_gpx)
        [OARootViewController.instance dismissViewControllerAnimated:NO completion:nil];
    else if (self.presentedViewController)
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setGpxRouteIfNeeded:(OAGPXDocument *)gpx
{
    if (!_gpx || gpx != _gpx)
    {
        _gpx = gpx;
        [[OARootViewController instance].mapPanel.mapActions setGPXRouteParamsWithDocument:_gpx path:_gpx.path];
        [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
        [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
    }
}

- (void)onSegmentSelected:(NSInteger)position gpx:(OAGPXDocument *)gpx
{
    OAAppSettings.sharedManager.gpxRouteSegment = position;
    
    [self setGpxRouteIfNeeded:gpx];
    
    OAGPXRouteParamsBuilder *paramsBuilder = OARoutingHelper.sharedInstance.getCurrentGPXRoute;
    if (paramsBuilder)
    {
        [paramsBuilder setSelectedSegment:position];
        NSArray<CLLocation *> *ps = [paramsBuilder getPoints];
        if (ps.count > 0)
        {
            OATargetPointsHelper *tg = [OATargetPointsHelper sharedInstance];
            [tg clearStartPoint:NO];
            CLLocation *loc = ps.lastObject;
            [tg navigateToPoint:loc updateRoute:true intermediate:-1];
        }
    }
    
    [self generateData];
    [self.tableView reloadData];
}

@end
