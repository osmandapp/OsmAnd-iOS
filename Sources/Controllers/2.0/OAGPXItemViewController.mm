//
//  OAGPXItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXItemViewController.h"
#import "OAGPXDetailsTableViewCell.h"
#import "OAGPXElevationTableViewCell.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "PXAlertView.h"

#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


@implementation OAGPXItemViewControllerState
@end


@interface OAGPXItemViewController ()<UIDocumentInteractionControllerDelegate> {

    OsmAndAppInstance _app;
    NSDateFormatter *dateTimeFormatter;
    
    OAMapViewController *_mapViewController;
    
    BOOL _startEndTimeExists;
    
    OAGpxSegmentType _segmentType;
    EPointsSortingType _sortingType;
    CGFloat _scrollPos;
    BOOL _wasInit;
}

@property (nonatomic) OAGPXDocument *doc;
@property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OAGPXItemViewController
{
    OASavingTrackHelper *_savingHelper;
    OAGPXWptListViewController *_waypointsController;
    BOOL _wasOpenedWaypointsView;
    
    NSInteger _sectionsCount;
    NSInteger _statSectionIndex;
    NSInteger _timeSectionIndex;
    NSInteger _uphillsSectionIndex;
}

@synthesize editing = _editing;
@synthesize wasEdited = _wasEdited;
@synthesize showingKeyboard = _showingKeyboard;

- (id)initWithGPXItem:(OAGPX *)gpxItem
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _wasInit = NO;
        _scrollPos = 0.0;
        _segmentType = kSegmentStatistics;
        _sortingType = EPointsSortingTypeGrouped;
        self.gpx = gpxItem;
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
        self.doc = [[OAGPXDocument alloc] initWithGpxFile:path];
    }
    return self;
}

- (id)initWithGPXItem:(OAGPX *)gpxItem ctrlState:(OAGPXItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _wasInit = NO;
        _segmentType = ctrlState.segmentType;
        _sortingType = ctrlState.sortType;
        _scrollPos = ctrlState.scrollPos;
        self.gpx = gpxItem;
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
        self.doc = [[OAGPXDocument alloc] initWithGpxFile:path];
        
    }
    return self;
}

- (id)initWithCurrentGPXItem
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _segmentType = kSegmentStatistics;
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
        
    }
    return self;
}

- (void)updateCurrentGPXData
{
    OAGPX* item = [_savingHelper getCurrentGPX];
    item.gpxTitle = OALocalizedString(@"track_recording_name");
    
    self.gpx = item;
    self.doc = (OAGPXDocument*)_savingHelper.currentTrack;
    
    [self.segmentView setEnabled:self.doc.locationMarks.count > 0 forSegmentAtIndex:1];
}


- (void)cancelPressed
{
    [_mapViewController hideTempGpxTrack];

    if (self.delegate)
        [self.delegate btnCancelPressed];

    [self closePointsController];
}

- (void)okPressed
{
    if (self.delegate)
        [self.delegate btnOkPressed];
    
    [self closePointsController];
}

- (BOOL)preHide
{
    [_mapViewController keepTempGpxTrackVisible];
    [_mapViewController hideTempGpxTrack];
    [self closePointsController];
    return YES;
}

-(BOOL)supportEditing
{
    return YES;
}

- (void)activateEditing
{
    _editing = YES;
    [self updateWaypointsButtons];
}

- (BOOL)supportFullScreen
{
    return YES;
}

-(BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;
{
    return YES;
}

- (id)getTargetObj
{
    return self.gpx;
}

- (CGFloat)contentHeight
{
    CGFloat h = 0.0;
    for (NSInteger i = 0; i < [_tableView numberOfSections]; i++)
    {
        h += 44.0;
        h += [self.tableView numberOfRowsInSection:i] * 44.0;
    }
    return MIN(160.0, h);
}

- (void)applyLocalization
{
    [self.buttonCancel setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [self.buttonCancel setImage:[UIImage imageNamed:@"menu_icon_back"] forState:UIControlStateNormal];
    [self.buttonCancel setTintColor:[UIColor whiteColor]];
    self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0);
    self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0);
    
    [self.segmentView setTitle:OALocalizedString(@"gpx_stat") forSegmentAtIndex:0];
    [self.segmentView setTitle:OALocalizedString(@"gpx_waypoints") forSegmentAtIndex:1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.titleView.text = [self.gpx getNiceTitle];
    _startEndTimeExists = self.gpx.startTime > 0 && self.gpx.endTime > 0;
    
    if (_startEndTimeExists)
    {
        _sectionsCount = 3;
        _statSectionIndex = 0;
        _timeSectionIndex = 1;
        _uphillsSectionIndex = 2;
    }
    else
    {
        _sectionsCount = 2;
        _statSectionIndex = 0;
        _timeSectionIndex = -1;
        _uphillsSectionIndex = 1;
    }

    
    self.buttonUpdate.frame = self.buttonMore.frame;
    self.buttonEdit.frame = self.buttonMore.frame;
    
    _tableView.dataSource = self;
    _tableView.delegate = self;

    [self.segmentView setSelectedSegmentIndex:_segmentType];
    [self applySegmentType];

    NSInteger wptCount = self.doc.locationMarks.count;
    [self.segmentView setEnabled:wptCount > 0 forSegmentAtIndex:1];
    if (wptCount > 0)
    {
        UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 50.0)];
        badgeLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
        badgeLabel.text = [NSString stringWithFormat:@"%d", wptCount];
        badgeLabel.textColor = UIColorFromRGB(0xFF8F00);
        badgeLabel.textAlignment = NSTextAlignmentCenter;
        [badgeLabel sizeToFit];
        
        CGSize badgeSize = CGSizeMake(MAX(16.0, badgeLabel.bounds.size.width + 8.0), MAX(16.0, badgeLabel.bounds.size.height));
        badgeLabel.frame = CGRectMake(0.0, 0.0, badgeSize.width, badgeSize.height);
        CGRect badgeFrame = CGRectMake(self.segmentView.bounds.size.width - badgeSize.width + 10.0, -4.0, badgeSize.width, badgeSize.height);
        UIView *badge = [[UIView alloc] initWithFrame:badgeFrame];
        badge.layer.cornerRadius = 8.0;
        badge.layer.backgroundColor = [UIColor whiteColor].CGColor;
        //badge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        [badge addSubview:badgeLabel];
        
        [self.segmentViewContainer addSubview:badge];
    }

    if (self.showCurrentTrack)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController hideTempGpxTrack];
            [_mapViewController showRecGpxTrack];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController showTempGpxTrack:self.gpx.gpxFileName];
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (OAGPXItemViewControllerState *) getCurrentState
{
    OAGPXItemViewControllerState *state = [[OAGPXItemViewControllerState alloc] init];
    state.segmentType = _segmentType;
    state.scrollPos = (_segmentType == kSegmentStatistics ? self.tableView.contentOffset.y : _waypointsController.tableView.contentOffset.y);
    state.sortType = _sortingType;
    
    return state;
}

- (void)closePointsController
{
    if (_waypointsController)
    {
        [_waypointsController resetData];
        [_waypointsController doViewDisappear];
        _waypointsController = nil;
    }
}

- (void)applySegmentType
{
    switch (_segmentType)
    {
        case kSegmentStatistics:
        {
            [self.tableView bringSubviewToFront:self.contentView];

            if (!_wasInit && _scrollPos != 0.0)
                [self.tableView setContentOffset:CGPointMake(0.0, _scrollPos)];
            
            if (_waypointsController)
            {
                [_waypointsController resetData];
                [_waypointsController doViewDisappear];
                [_waypointsController.tableView removeFromSuperview];
            }
            
            self.buttonSort.hidden = YES;
            self.buttonEdit.hidden = YES;
            if (self.showCurrentTrack)
            {
                self.buttonMore.hidden = YES;
                self.buttonUpdate.hidden = NO;
            }
            else
            {
                self.buttonMore.hidden = NO;
                self.buttonUpdate.hidden = YES;
            }
            
            break;
        }
        case kSegmentWaypoints:
        {
            self.buttonUpdate.hidden = YES;
            [self updateWaypointsButtons];
            
            if (!_waypointsController)
            {
                _waypointsController = [[OAGPXWptListViewController alloc] initWithLocationMarks:self.doc.locationMarks];
                _waypointsController.sortingType = _sortingType;
                [_waypointsController updateSortButton:self.buttonSort];
            }

            _waypointsController.view.frame = self.tableView.frame;
            [_waypointsController doViewAppear];
            [self.contentView addSubview:_waypointsController.tableView];

            if (!_wasInit && _scrollPos != 0.0)
                [_waypointsController.tableView setContentOffset:CGPointMake(0.0, _scrollPos)];

            if (!_wasOpenedWaypointsView && self.delegate)
                [self.delegate requestFullScreenMode];
            
            _wasOpenedWaypointsView = YES;

            break;
        }
            
        default:
            break;
    }
    
    _wasInit = YES;
}

- (void)updateWaypointsButtons
{
    self.buttonSort.hidden = self.editing;
    self.buttonEdit.hidden = YES;//self.editing;
    self.buttonMore.hidden = NO;//!self.editing;
}

- (IBAction)threeDotsClicked:(id)sender
{
    [PXAlertView showAlertWithTitle:[self.gpx getNiceTitle]
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:@[OALocalizedString(@"shared_string_remove"), OALocalizedString(@"gpx_export")]
                        otherImages:@[@"track_clear_data.png", @"ic_dialog_export.png"]
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 if (buttonIndex == 0)
                                     [self deleteClicked:nil];
                                 else
                                     [self exportClicked:nil];
                             }
                         }];
}

- (void)updateMap
{
    [[OARootViewController instance].mapPanel displayGpxOnMap:self.gpx];
}

- (IBAction)updateClicked:(id)sender
{
    [self updateCurrentGPXData];
    [self updateMap];
    [_tableView reloadData];
    if (self.delegate)
        [self.delegate contentChanged];
}

- (IBAction)sortClicked:(id)sender
{
    if (_waypointsController)
    {
        [_waypointsController doSortClick:self.buttonSort];
        _sortingType = _waypointsController.sortingType;
    }
}

- (IBAction)editClicked:(id)sender
{
    _editing = !_editing;
    [self updateWaypointsButtons];
}

- (IBAction)segmentClicked:(id)sender
{
    OAGpxSegmentType newSegmentType = (OAGpxSegmentType)self.segmentView.selectedSegmentIndex;
    if (_segmentType == newSegmentType)
        return;
    
    _editing = NO;
    _segmentType = newSegmentType;
        
    [self applySegmentType];
}

- (IBAction)exportClicked:(id)sender
{
    
    NSURL* gpxUrl = [NSURL fileURLWithPath:[_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFileName]];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:gpxUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = _gpx.gpxFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.navController.view
                                         animated:YES];
}

- (IBAction)deleteClicked:(id)sender
{
    [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_remove")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     
                                     OAAppSettings *settings = [OAAppSettings sharedManager];
                                     if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]) {
                                         [settings hideGpx:self.gpx.gpxFileName];
                                         [_mapViewController hideTempGpxTrack];
                                         [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
                                     }
                                     
                                     [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
                                     [[OAGPXDatabase sharedDb] save];
                                     
                                     [self okPressed];
                                 });
                             }
                         }];
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sectionsCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _statSectionIndex)
        return OALocalizedString(@"gpx_stat");
    else if (section == _timeSectionIndex)
        return OALocalizedString(@"gpx_route_time");
    else if (section == _uphillsSectionIndex)
        return OALocalizedString(@"gpx_uphldownhl");
    else
        return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _statSectionIndex)
        return 4;
    else if (section == _timeSectionIndex)
        return 4;
    else if (section == _uphillsSectionIndex)
        return 4;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierPoint = @"OAGPXDetailsTableViewCell";

    if (indexPath.section == _statSectionIndex)
    {
        OAGPXDetailsTableViewCell* cell;
        cell = (OAGPXDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXDetailCell" owner:self options:nil];
            cell = (OAGPXDetailsTableViewCell *)[nib objectAtIndex:0];
        }
        
        switch (indexPath.row)
        {
            case 0: // Distance (points)
            {
                NSMutableString *distanceStr = [[_app getFormattedDistance:self.gpx.totalDistance] mutableCopy];
                if (self.gpx.points > 0)
                    [distanceStr appendFormat:@" (%d)", self.gpx.points];
                
                [cell.textView setText:OALocalizedString(@"gpx_distance_points")];
                [cell.descView setText:distanceStr];
                cell.iconView.hidden = YES;
                break;
            }
            case 1: // Waypoints
            {
                [cell.textView setText:OALocalizedString(@"gpx_waypoints")];
                [cell.descView setText:[NSString stringWithFormat:@"%d", self.gpx.wptPoints]];
                cell.iconView.hidden = YES;
                break;
            }
            case 2: // Average speed
            {
                [cell.textView setText:OALocalizedString(@"gpx_average_speed")];
                [cell.descView setText:[_app getFormattedSpeed:self.gpx.avgSpeed]];
                cell.iconView.hidden = YES;
                break;
            }
            case 3: // Max speed
            {
                [cell.textView setText:OALocalizedString(@"gpx_max_speed")];
                [cell.descView setText:[_app getFormattedSpeed:self.gpx.maxSpeed]];
                cell.iconView.hidden = YES;
                break;
            }
                
            default:
                break;
        }
        
        return cell;
    }
    else if (indexPath.section == _timeSectionIndex)
    {
        OAGPXDetailsTableViewCell* cell;
        cell = (OAGPXDetailsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXDetailCell" owner:self options:nil];
            cell = (OAGPXDetailsTableViewCell *)[nib objectAtIndex:0];
        }
        
        switch (indexPath.row)
        {
            case 0: // Start Time
            {
                [cell.textView setText:OALocalizedString(@"gpx_start")];
                [cell.descView setText:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.gpx.startTime]]];
                cell.iconView.hidden = YES;
                break;
            }
            case 1: // Finish Time
            {
                [cell.textView setText:OALocalizedString(@"gpx_finish")];
                [cell.descView setText:[dateTimeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.gpx.endTime]]];
                cell.iconView.hidden = YES;
                break;
            }
            case 2: // Total Time
            {
                [cell.textView setText:OALocalizedString(@"total_time")];
                [cell.descView setText:[_app getFormattedTimeInterval:self.gpx.timeSpan shortFormat:NO]];
                cell.iconView.hidden = YES;
                break;
            }
            case 3: // Moving Time
            {
                [cell.textView setText:OALocalizedString(@"moving_time")];
                [cell.descView setText:[_app getFormattedTimeInterval:self.gpx.timeMoving shortFormat:NO]];
                cell.iconView.hidden = YES;
                break;
            }
                
            default:
                break;
        }
        
        return cell;
    }
    else if (indexPath.section == _uphillsSectionIndex)
    {
        static NSString* const reusableIdentifierPointElev = @"OAGPXElevationTableViewCell";
        
        OAGPXElevationTableViewCell* cell;
        cell = (OAGPXElevationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPointElev];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXElevationCell" owner:self options:nil];
            cell = (OAGPXElevationTableViewCell *)[nib objectAtIndex:0];
        }
        
        switch (indexPath.row) {
            case 0: // Avg Elevation
            {
                [cell.textView setText:OALocalizedString(@"gpx_avg_elev")];
                [cell.elev1View setText:[_app getFormattedAlt:self.gpx.avgElevation]];
                cell.showArrows = NO;
                cell.showUpDown = NO;
                break;
            }
            case 1: // Elevation Range
            {
                [cell.textView setText:OALocalizedString(@"gpx_elev_range")];
                [cell.elev1View setText:[_app getFormattedAlt:self.gpx.minElevation]];
                [cell.elev2View setText:[_app getFormattedAlt:self.gpx.maxElevation]];
                cell.showArrows = NO;
                cell.showUpDown = YES;
                break;
            }
            case 2: // Up/Down
            {
                [cell.textView setText:OALocalizedString(@"gpx_updown")];
                [cell.elev1View setText:[_app getFormattedAlt:self.gpx.diffElevationDown]];
                [cell.elev2View setText:[_app getFormattedAlt:self.gpx.diffElevationUp]];
                cell.showArrows = YES;
                cell.showUpDown = YES;
                break;
            }
            case 3: // Uphills Total
            {
                [cell.textView setText:OALocalizedString(@"gpx_uphills_total")];
                [cell.elev1View setText:[_app getFormattedAlt:self.gpx.maxElevation - self.gpx.minElevation]];
                cell.showArrows = NO;
                cell.showUpDown = NO;
                break;
            }
                
            default:
                break;
        }
        
        return cell;
    }
    
    return nil;
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

@end
