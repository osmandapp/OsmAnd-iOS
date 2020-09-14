//
//  OAGPXItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXItemViewController.h"
#import "OAGPXDetailsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAColorViewCell.h"
#import "OAGPXElevationTableViewCell.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "PXAlertView.h"
#import "OAEditGroupViewController.h"
#import "OAEditColorViewController.h"
#import "OAEditGPXColorViewController.h"
#import "OAGPXTrackColorCollection.h"
#import "OADefaultFavorite.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXRouter.h"
#import "OASizes.h"

#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"
#import "OAGpxWptItem.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


@implementation OAGPXItemViewControllerState
@end


@interface OAGPXItemViewController ()<UIDocumentInteractionControllerDelegate, OAEditGroupViewControllerDelegate, OAEditColorViewControllerDelegate, OAEditGPXColorViewControllerDelegate, OAGPXWptListViewControllerDelegate, UIAlertViewDelegate> {

    OsmAndAppInstance _app;
    NSDateFormatter *dateTimeFormatter;
    
    OAMapViewController *_mapViewController;
    
    BOOL _startEndTimeExists;
    
    OAGpxSegmentType _segmentType;
    EPointsSortingType _sortingType;
    CGFloat _scrollPos;
    BOOL _wasInit;
    BOOL _cancelPressed;
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
    NSInteger _controlsSectionIndex;
    NSInteger _speedSectionIndex;
    NSInteger _timeSectionIndex;
    NSInteger _uphillsSectionIndex;
    
    NSString *_exportFileName;
    NSString *_exportFilePath;

    NSArray* _groups;
    
    OAEditGroupViewController *_groupController;
    OAEditColorViewController *_colorController;
    
    OAEditGPXColorViewController *_trackColorController;
    OAGPXTrackColorCollection *_gpxColorCollection;
    
    UIView *_badge;
    CALayer *_horizontalLine;
    
    UIView *_headerView;
}

@synthesize editing = _editing;
@synthesize wasEdited = _wasEdited;
@synthesize showingKeyboard = _showingKeyboard;

- (id)initWithGPXItem:(OAGPX *)gpxItem
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _wasInit = NO;
        _scrollPos = 0.0;
        _segmentType = kSegmentStatistics;
        _sortingType = EPointsSortingTypeGrouped;
        self.gpx = gpxItem;
        [self loadDoc];
    }
    return self;
}

- (id)initWithGPXItem:(OAGPX *)gpxItem ctrlState:(OAGPXItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _wasInit = NO;
        _segmentType = ctrlState.segmentType;
        _sortingType = ctrlState.sortType;
        _scrollPos = ctrlState.scrollPos;
        self.gpx = gpxItem;
        [self loadDoc];
    }
    return self;
}

- (id)initWithCurrentGPXItem
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _segmentType = kSegmentStatistics;
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
    }
    return self;
}

- (id)initWithCurrentGPXItem:(OAGPXItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        _segmentType = ctrlState.segmentType;
        _sortingType = ctrlState.sortType;
        _scrollPos = ctrlState.scrollPos;

        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
    }
    return self;
}

-(NSAttributedString *)getAttributedTypeStr
{
    return [OAGPXItemViewController getAttributedTypeStr:self.gpx labelWidth: 230.0];
}

-(NSAttributedString *)getAttributedTypeStrForWidth:(CGFloat)labelWidth
{
    return [OAGPXItemViewController getAttributedTypeStr:self.gpx labelWidth:labelWidth];
}

+(NSAttributedString *)getAttributedTypeStr:(OAGPX *)item labelWidth:(CGFloat)labelWidth
{
    NSString *separator = @"|";
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:12];
    
    if (item.newGpx && item.wptPoints == 0)
    {
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:OALocalizedString(@"select_wpt_on_map")]];
    }
    else
    {
        NSMutableString *distanceStr = [[[OsmAndApp instance] getFormattedDistance:item.totalDistance] mutableCopy];
        if (item.points > 0)
            [distanceStr appendFormat:@" (%d)", item.points];
        NSString *waypointsStr = [NSString stringWithFormat:@"%d", item.wptPoints];
        NSString *timeMovingStr = [[OsmAndApp instance] getFormattedTimeInterval:item.timeMoving shortFormat:NO];
        NSString *avgSpeedStr = [[OsmAndApp instance] getFormattedSpeed:item.avgSpeed];
        
        NSMutableAttributedString *stringDistance = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", distanceStr]];
        NSMutableAttributedString *stringWaypoints = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", waypointsStr]];
        NSMutableAttributedString *stringTimeMoving;
        if (item.timeMoving > 0)
            stringTimeMoving = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@    %@", separator, timeMovingStr]];
        NSMutableAttributedString *stringAvgSpeed;
        if (item.avgSpeed > 0)
            stringAvgSpeed =[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", avgSpeedStr]];
        
        NSTextAttachment *distanceAttachment = [[NSTextAttachment alloc] init];
        distanceAttachment.image = [UIImage imageNamed:@"ic_gpx_distance.png"];
        
        NSTextAttachment *waypointsAttachment = [[NSTextAttachment alloc] init];
        waypointsAttachment.image = [UIImage imageNamed:@"ic_gpx_points.png"];
        
        NSTextAttachment *timeMovingAttachment;
        if (item.timeMoving > 0)
        {
            timeMovingAttachment = [[NSTextAttachment alloc] init];
            timeMovingAttachment.image = [UIImage imageNamed:@"ic_travel_time.png"];
        }
        NSTextAttachment *avgSpeedAttachment;
        if (item.avgSpeed > 0)
        {
            avgSpeedAttachment = [[NSTextAttachment alloc] init];
            avgSpeedAttachment.image = [UIImage imageNamed:@"ic_average_speed.png"];
        }
        
        NSAttributedString *distanceStringWithImage = [NSAttributedString attributedStringWithAttachment:distanceAttachment];
        NSAttributedString *waypointsStringWithImage = [NSAttributedString attributedStringWithAttachment:waypointsAttachment];
        NSAttributedString *timeMovingStringWithImage;
        if (item.timeMoving > 0)
            timeMovingStringWithImage = [NSAttributedString attributedStringWithAttachment:timeMovingAttachment];
        NSAttributedString *avgSpeedStringWithImage;
        if (item.avgSpeed > 0)
            avgSpeedStringWithImage = [NSAttributedString attributedStringWithAttachment:avgSpeedAttachment];
        
        [stringDistance replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:distanceStringWithImage];
        [stringDistance addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
        [stringWaypoints replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:waypointsStringWithImage];
        [stringWaypoints addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
        if (item.timeMoving > 0)
        {
            [stringTimeMoving replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:timeMovingStringWithImage];
            [stringTimeMoving addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
        }
        if (item.avgSpeed > 0)
        {
            [stringAvgSpeed replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:avgSpeedStringWithImage];
            [stringAvgSpeed addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
        }
        
        [string appendAttributedString:stringDistance];
        [string appendAttributedString:stringWaypoints];
        if (stringTimeMoving)
            [string appendAttributedString:stringTimeMoving];
        if (stringAvgSpeed)
            [string appendAttributedString:stringAvgSpeed];
    }
    
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
    
    CGRect textRect = [string boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGFloat textWidth = textRect.size.width;
    NSString *replacingString = [NSString stringWithFormat:@"%@ ", separator];
    if (textWidth >= labelWidth)
        [string.mutableString replaceOccurrencesOfString:replacingString withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, string.length)];
    else
        [string.mutableString replaceOccurrencesOfString:replacingString withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, string.length)];
    
    return string;
}

-(CGFloat) getNavBarHeight
{
    return gpxItemNavBarHeight;
}

- (void)updateCurrentGPXData
{
    OAGPX* item = [_savingHelper getCurrentGPX];
    item.gpxTitle = OALocalizedString(@"track_recording_name");
    
    self.gpx = item;
    self.doc = (OAGPXDocument*)_savingHelper.currentTrack;
}

- (void)loadDoc
{
    OAGPXRouter *gpxRouter = [OAGPXRouter sharedInstance];
    if (gpxRouter.gpx && [gpxRouter.gpx.gpxFileName isEqualToString:self.gpx.gpxFileName])
        [gpxRouter cancelRoute];
    
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
    self.doc = [[OAGPXDocument alloc] initWithGpxFile:path];
}

- (void)cancelPressed
{
    _cancelPressed = YES;
    
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
    [self closePointsController];
    [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
    return YES;
}

-(BOOL)disablePanWhileEditing
{
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

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return YES;
}

-(BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (id) getTargetObj
{
    return self.gpx;
}

- (BOOL) disableScroll
{
    return self.isLandscape && _segmentType == kSegmentWaypoints;
}

- (CGFloat) contentHeight
{
    return self.isLandscape || OAUtilities.isIPad ? DeviceScreenHeight - self.delegate.getHeaderViewHeight - self.getNavBarHeight - OAUtilities.getStatusBarHeight : DeviceScreenHeight - self.getNavBarHeight - self.delegate.getHeaderViewHeight + OAUtilities.getBottomMargin;
}

- (void) applyLocalization
{
    [self.segmentView setTitle:OALocalizedString(@"gpx_stat") forSegmentAtIndex:0];
    [self.segmentView setTitle:OALocalizedString(@"gpx_waypoints") forSegmentAtIndex:1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _gpxColorCollection = [[OAGPXTrackColorCollection alloc] initWithMapViewController:_mapViewController];

    dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.titleView.text = [self.gpx getNiceTitle];
    _startEndTimeExists = self.gpx.startTime > 0 && self.gpx.endTime > 0;
    
    BOOL uphillsDataExists = (self.gpx.avgElevation != 0.0 || self.gpx.minElevation != 0.0 || self.gpx.maxElevation != 0.0 || self.gpx.diffElevationDown != 0.0 || self.gpx.diffElevationUp != 0.0);
    
    _controlsSectionIndex = _showCurrentTrack ? -1 : 0;
    NSInteger nextSectionIndex = _showCurrentTrack ? 0 : 1;
    
    if (_startEndTimeExists)
    {
        _speedSectionIndex = (self.gpx.avgSpeed > 0 && self.gpx.maxSpeed > 0 ? nextSectionIndex++ : -1);
        _timeSectionIndex = nextSectionIndex++;
        _uphillsSectionIndex = (uphillsDataExists ? nextSectionIndex++ : -1);
    }
    else
    {
        _speedSectionIndex = (self.gpx.avgSpeed > 0 && self.gpx.maxSpeed > 0 ? nextSectionIndex++ : -1);
        _timeSectionIndex = -1;
        _uphillsSectionIndex = (uphillsDataExists ? nextSectionIndex++ : -1);
    }
    _sectionsCount = nextSectionIndex;

    if (_sectionsCount == (_showCurrentTrack ? 0 : 1))
    {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _tableView.frame.size.width, 100.0)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:_headerView.bounds];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.font = [UIFont systemFontOfSize:19.0];
        headerLabel.text = OALocalizedString(@"no_statistics");
        headerLabel.textColor = [UIColor lightGrayColor];
        headerLabel.numberOfLines = 3;
        [_headerView addSubview:headerLabel];
        [_tableView setTableHeaderView:_headerView];
    }
    
    self.buttonUpdate.frame = self.buttonSort.frame;
    self.buttonEdit.frame = self.buttonMore.frame;
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.estimatedRowHeight = kEstimatedRowHeight;

    [self updateEditingMode:NO animated:NO];

    [self.segmentView setSelectedSegmentIndex:_segmentType];
    [self applySegmentType];
    [self resetSortModeIfNeeded];
    [self addBadge];

    if (self.showCurrentTrack)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController hideTempGpxTrack];
            [_mapViewController showRecGpxTrack:YES];
        });
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapViewController showTempGpxTrack:self.gpx.gpxFileName];
        });
    }
    
    self.editToolbarView.hidden = YES;
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.editToolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.editToolbarView.layer addSublayer:_horizontalLine];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, 0.5);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addBadge
{
    if (_badge)
    {
        [_badge removeFromSuperview];
        _badge = nil;
    }
    
    UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 50.0)];
    badgeLabel.font = [UIFont systemFontOfSize:11.0];
    badgeLabel.text = [NSString stringWithFormat:@"%d", (int) self.doc.locationMarks.count];
    badgeLabel.textColor = UIColorFromRGB(0xFF8F00);
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    [badgeLabel sizeToFit];
    
    CGSize badgeSize = CGSizeMake(MAX(16.0, badgeLabel.bounds.size.width + 8.0), MAX(16.0, badgeLabel.bounds.size.height));
    badgeLabel.frame = CGRectMake(.5, .5, badgeSize.width, badgeSize.height);
    CGRect badgeFrame = CGRectMake(self.segmentView.bounds.size.width - badgeSize.width + 10.0, -4.0, badgeSize.width, badgeSize.height);
    _badge = [[UIView alloc] initWithFrame:badgeFrame];
    _badge.layer.cornerRadius = 8.0;
    _badge.layer.backgroundColor = [UIColor whiteColor].CGColor;
    
    [_badge addSubview:badgeLabel];
    
    [self.segmentViewContainer addSubview:_badge];
}

- (void)resetSortModeIfNeeded
{
    if (self.doc.locationMarks.count == 0)
    {
        _sortingType = EPointsSortingTypeGrouped;
        if (_waypointsController)
        {
            _waypointsController.sortingType = _sortingType;
            [_waypointsController updateSortButton:self.buttonSort];
        }
    }
}

- (OATargetMenuViewControllerState *) getCurrentState
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
            _editing = NO;
            
            self.tableView.hidden = NO;

            if (!_wasInit && _scrollPos != 0.0)
                [self.tableView setContentOffset:CGPointMake(0.0, _scrollPos)];
            
            if (_waypointsController)
            {
                [_waypointsController resetData];
                [_waypointsController doViewDisappear];
                [_waypointsController.view removeFromSuperview];
            }
            
            self.buttonSort.hidden = YES;
            self.buttonEdit.hidden = YES;
            if (self.showCurrentTrack)
            {
                self.buttonMore.hidden = NO;
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
                _waypointsController.delegate = self;
                _waypointsController.sortingType = _sortingType;
                [_waypointsController updateSortButton:self.buttonSort];
                _waypointsController.allGroups = [self readGroups];
            }
            
            if (self.delegate)
                [self.delegate contentChanged];
            _waypointsController.view.frame = self.isLandscape ? CGRectMake(0.0, 0.0, self.contentView.frame.size.width, [self contentHeight]) : self.contentView.bounds;
            [_waypointsController doViewAppear];
            [self.contentView addSubview:_waypointsController.view];

            self.tableView.hidden = YES;
            
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
    self.buttonCancel.hidden = self.editing;
    self.buttonSort.hidden = self.editing;
    self.buttonMore.hidden = YES;

    self.buttonEdit.hidden = NO;
    if (self.editing)
        [self.buttonEdit setImage:[UIImage imageNamed:@"icon_edit_active"] forState:UIControlStateNormal];
    else
        [self.buttonEdit setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];

    NSInteger wptCount = self.doc.locationMarks.count;
    self.buttonSort.enabled = wptCount;
    self.buttonEdit.enabled = wptCount;
}

- (NSArray *)readGroups
{
    NSMutableSet *groups = [NSMutableSet set];
    for (OAGpxWpt *wptItem in self.doc.locationMarks)
    {
        if (wptItem.type.length > 0)
            [groups addObject:wptItem.type];
    }
    _groups = [groups allObjects];
    
    return _groups;
}

- (IBAction)threeDotsClicked:(id)sender
{
    switch (_segmentType)
    {
        case kSegmentStatistics:
        {
            if (self.gpx.newGpx || self.showCurrentTrack)
            {
                [PXAlertView showAlertWithTitle:[self.gpx getNiceTitle]
                                        message:nil
                                    cancelTitle:OALocalizedString(@"shared_string_cancel")
                                    otherTitles:@[(self.showCurrentTrack ? OALocalizedString(@"track_clear") : OALocalizedString(@"shared_string_remove")), OALocalizedString(@"gpx_export")]
                                      otherDesc:nil
                                    otherImages:@[@"track_clear_data.png", @"ic_dialog_export.png"]
                                     completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                         if (!cancelled)
                                         {
                                             switch (buttonIndex)
                                             {
                                                 case 0:
                                                     [self deleteClicked:nil];
                                                     break;
                                                 case 1:
                                                     [self exportClicked:nil];
                                                     break;
                                                     
                                                 default:
                                                     break;
                                             }
                                         }
                                     }];
            }
            else
            {
                [PXAlertView showAlertWithTitle:[self.gpx getNiceTitle]
                                        message:nil
                                    cancelTitle:OALocalizedString(@"shared_string_cancel")
                                    otherTitles:@[OALocalizedString(@"fav_rename"), (self.showCurrentTrack ? OALocalizedString(@"track_clear") : OALocalizedString(@"shared_string_remove")),
                                                  OALocalizedString(@"gpx_export"),
                                                  OALocalizedString(@"gpx_edit_mode"),
                                                  OALocalizedString(@"product_title_trip_planning")]
                                      otherDesc:nil
                                    otherImages:@[@"ic_dialog_rename.png", @"track_clear_data.png", @"ic_dialog_export.png", @"ic_dialog_edit.png", @"ic_action_route_distance.png"]
                                     completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                         if (!cancelled)
                                         {
                                             switch (buttonIndex)
                                             {
                                                 case 0:
                                                     [self renameTrip];
                                                     break;
                                                 case 1:
                                                     [self deleteClicked:nil];
                                                     break;
                                                 case 2:
                                                     [self exportClicked:nil];
                                                     break;
                                                 case 3:
                                                     // enter edit mode
                                                     [[OARootViewController instance].mapPanel openTargetViewWithGPXEdit:self.gpx pushed:NO];
                                                     break;
                                                 case 4:
                                                     [[OARootViewController instance].mapPanel targetGoToGPXRoute];
                                                     break;

                                                 default:
                                                     break;
                                             }
                                         }
                                     }];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void)changeGroup
{
    NSArray *selectedRows = [_waypointsController.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"wpt_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    _groupController = [[OAEditGroupViewController alloc] initWithGroupName:nil groups:_groups];
    _groupController.delegate = self;
    [self.navController pushViewController:_groupController animated:YES];
}

- (void)changeColor
{
    NSArray *selectedRows = [_waypointsController.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"wpt_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    _colorController = [[OAEditColorViewController alloc] init];
    _colorController.delegate = self;
    [self.navController pushViewController:_colorController animated:YES];
}

- (void)deleteWaypoints
{
    NSArray *selectedRows = [_waypointsController.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"wpt_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_remove_wpts_q")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                          otherDesc:nil
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 NSArray *items = [_waypointsController getSelectedItems];
                                 if (_showCurrentTrack)
                                 {
                                     for (OAGpxWptItem *item in items)
                                         [_savingHelper deleteWpt:item.point];

                                     // update map
                                     [[_app trackRecordingObservable] notifyEvent];
                                 }
                                 else
                                 {
                                     NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
                                     [_mapViewController deleteWpts:items docPath:path];
                                     [self loadDoc];
                                 }

                                 [_waypointsController setPoints:self.doc.locationMarks];
                                 [_waypointsController generateData];
                                 [self addBadge];
                                 [self resetSortModeIfNeeded];
                                 [self editClicked:nil];
                                 if (self.delegate)
                                     [self.delegate contentChanged];
                             }
                         }];
}

- (void)exportWaypoints
{
    NSArray *selectedRows = [_waypointsController.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"wpt_select") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    OAGPXMutableDocument *gpx = [[OAGPXMutableDocument alloc] init];
    NSArray *items = [_waypointsController getSelectedItems];
    for (OAGpxWptItem *item in items)
        [gpx addWpt:item.point];

    _exportFileName = [@"exported_waypoints" stringByAppendingString:@".gpx"];
    _exportFilePath = [NSTemporaryDirectory() stringByAppendingString:_exportFileName];
    [gpx saveTo:_exportFilePath];
    
    NSURL* gpxUrl = [NSURL fileURLWithPath:_exportFilePath];
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:gpxUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.navController.view
                                         animated:YES];
    [self editClicked:nil];
}

- (void)updateMap
{
    [[OARootViewController instance].mapPanel displayGpxOnMap:self.gpx];
}

- (BOOL) isLandscape
{
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;;
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
    if (self.delegate)
        [self.delegate requestFullScreenMode];
    [self updateEditingMode:self.editing animated:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.delegate && _editing)
            [self.delegate requestFullScreenMode];
        if (self.delegate && self.isLandscape)
            [self.delegate contentChanged];
        [self updateEditingMode:_editing animated:NO];
    } completion:nil];
}

- (void)updateEditingMode:(BOOL)value animated:(BOOL)animated
{
    [_waypointsController.tableView beginUpdates];
    [_waypointsController setEditing:value animated:YES];
    [self updateWaypointsButtons];
    
    if (value)
        self.titleView.text = OALocalizedString(@"editing_waypoints");
    else
        self.titleView.text = [self.gpx getNiceTitle];
    
    if (value)
    {
        _horizontalLine.frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, 0.5);

        CGSize cs = self.contentView.bounds.size;
        CGRect f = self.editToolbarView.frame;
        f.size.height = favoritesToolBarHeight + [OAUtilities getBottomMargin];
        f.origin.y = [self contentHeight] - f.size.height;
        self.editToolbarView.hidden = NO;
        [UIView animateWithDuration:(animated ? .3 : 0.0) animations:^{
            self.editToolbarView.frame = f;
            _waypointsController.view.frame = CGRectMake(0.0, 0.0, cs.width, [self contentHeight] - f.size.height);
        }];
    }
    else
    {
        CGSize cs = self.contentView.bounds.size;
        CGRect f = self.editToolbarView.frame;
        f.origin.y = cs.height + 1.0;
        
        [UIView animateWithDuration:(animated ? .3 : 0.0) animations:^{
            self.editToolbarView.frame = f;
            _waypointsController.view.frame = self.isLandscape ? CGRectMake(0.0, 0.0, cs.width, [self contentHeight]) : self.contentView.bounds;
        } completion:^(BOOL finished) {
            self.editToolbarView.hidden = YES;
        }];
    }
    [_waypointsController.tableView endUpdates];
}

- (IBAction)segmentClicked:(id)sender
{
    OAGpxSegmentType newSegmentType = (OAGpxSegmentType)self.segmentView.selectedSegmentIndex;
    if (_segmentType == newSegmentType)
        return;
    
    _editing = NO;
    [self updateEditingMode:self.editing animated:NO];

    _segmentType = newSegmentType;
        
    [self applySegmentType];
}

- (IBAction)exportClicked:(id)sender
{
    if (_showCurrentTrack)
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];

        NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
        [simpleFormat setDateFormat:@"HH-mm_EEE"];
        
        _exportFileName = [NSString stringWithFormat:@"%@_%@", [fmt stringFromDate:[NSDate date]], [simpleFormat stringFromDate:[NSDate date]]];
        _exportFilePath = [NSString stringWithFormat:@"%@/%@.gpx", NSTemporaryDirectory(), _exportFileName];

        [_savingHelper saveCurrentTrack:_exportFilePath];
    }
    else
    {
        _exportFileName = _gpx.gpxFileName;
        _exportFilePath = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFileName];
    }
    
    NSURL* gpxUrl = [NSURL fileURLWithPath:_exportFilePath];
    
    _exportController = [UIDocumentInteractionController interactionControllerWithURL:gpxUrl];
    _exportController.UTI = @"net.osmand.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.navController.view
                                         animated:YES];
}

- (void)renameTrip
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"gpx_rename_q") message:OALocalizedString(@"gpx_enter_new_name \"%@\"", self.gpx.gpxTitle) delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles: OALocalizedString(@"shared_string_ok"), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text = self.gpx.gpxTitle;
    [alert show];
}

- (void)goToMap
{
    if (self.delegate)
        [self.delegate btnOkPressed];
}

- (IBAction)deleteClicked:(id)sender
{
    [PXAlertView showAlertWithTitle:(self.showCurrentTrack ? OALocalizedString(@"track_clear_q") : OALocalizedString(@"gpx_remove"))
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                          otherDesc:nil
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     
                                     OAAppSettings *settings = [OAAppSettings sharedManager];
                                     
                                     if (self.showCurrentTrack)
                                     {
                                         settings.mapSettingTrackRecording = NO;
                                         [[OASavingTrackHelper sharedInstance] clearData];
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [_mapViewController hideRecGpxTrack];
                                             //[_widgetsView updateGpxRec];
                                         });
                                     }
                                     else
                                     {
                                         if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]) {
                                             [settings hideGpx:@[self.gpx.gpxFileName]];
                                             [_mapViewController hideTempGpxTrack];
                                             [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
                                         }
                                         
                                         [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
                                         [[OAGPXDatabase sharedDb] save];
                                     }
                                     [self cancelPressed];
                                 });
                             }
                         }];
}


- (IBAction)waypointsExportClicked:(id)sender
{
    [self exportWaypoints];
}

- (IBAction)waypointsGroupClicked:(id)sender
{
    [self changeGroup];
}

- (IBAction)waypointsColorClicked:(id)sender
{
    [self changeColor];
}

- (IBAction)waypointsDeleteClicked:(id)sender
{
    [self deleteWaypoints];
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

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    if (_showCurrentTrack && _exportFilePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:_exportFilePath error:nil];
        _exportFilePath = nil;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sectionsCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == _speedSectionIndex)
        return OALocalizedString(@"gpx_speed");
    else if (section == _timeSectionIndex)
        return OALocalizedString(@"gpx_route_time");
    else if (section == _uphillsSectionIndex)
        return OALocalizedString(@"gpx_uphldownhl");
    else
        return @"";
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == _controlsSectionIndex)
        return 2;
    else if (section == _speedSectionIndex)
        return 2;
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

    if (indexPath.section == _controlsSectionIndex)
    {
        switch (indexPath.row)
        {
            case 0:
            {
                static NSString* const identifierCell = @"OASwitchTableViewCell";
                OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
                    cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
                }
                
                if (cell)
                {
                    OAAppSettings *settings = [OAAppSettings sharedManager];
                    cell.textView.text = OALocalizedString(@"map_settings_show");
                    cell.switchView.tag = indexPath.section << 10 | indexPath.row;
                    [cell.switchView setOn:[settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]];
                    [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
                }
                return cell;
            }
            case 1:
            {
                OAColorViewCell* cell;
                static NSString* const reusableIdentifierColorCell = @"OAColorViewCell";
                cell = (OAColorViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierColorCell];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorViewCell" owner:self options:nil];
                    cell = (OAColorViewCell *)[nib objectAtIndex:0];
                }

                OAGPXTrackColor *gpxColor = [_gpxColorCollection getColorForValue:_gpx.color];
                cell.colorIconView.layer.cornerRadius = cell.colorIconView.frame.size.height / 2;
                cell.colorIconView.backgroundColor = gpxColor.color;
                [cell.descriptionView setText:gpxColor.name];
                
                cell.textView.text = OALocalizedString(@"fav_color");
                cell.backgroundColor = UIColorFromRGB(0xffffff);
                
                return cell;
            }
            default:
                break;
        }
    }
    if (indexPath.section == _speedSectionIndex)
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
            case 0: // Average speed
            {
                [cell.textView setText:OALocalizedString(@"gpx_average_speed")];
                [cell.descView setText:[_app getFormattedSpeed:self.gpx.avgSpeed]];
                cell.iconView.hidden = YES;
                break;
            }
            case 1: // Max speed
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

- (BOOL) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (sw.isOn)
    {
        [settings showGpx:@[self.gpx.gpxFileName] update:NO];
        [_mapViewController hideTempGpxTrack:NO];
        [[OARootViewController instance].mapPanel prepareMapForReuse:nil mapBounds:self.gpx.bounds newAzimuth:0.0 newElevationAngle:90.0 animated:NO];
    }
    else if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName])
    {
        [settings hideGpx:@[self.gpx.gpxFileName] update:NO];
        [_mapViewController showTempGpxTrack:self.gpx.gpxFileName update:NO];
    }
    return NO;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _controlsSectionIndex && indexPath.row == 1)
    {
        _trackColorController = [[OAEditGPXColorViewController alloc] initWithColorValue:_gpx.color colorsCollection:_gpxColorCollection];
        _trackColorController.delegate = self;
        [self.navController pushViewController:_trackColorController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _controlsSectionIndex && indexPath.row == 0) {
        return UITableViewAutomaticDimension;
    }
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


#pragma mark - OAEditGroupViewControllerDelegate

-(void)groupChanged
{
    NSArray *items = [_waypointsController getSelectedItems];
    NSString *newGroup = _groupController.groupName;
    
    for (OAGpxWptItem *item in items)
    {
        item.point.type = newGroup;
        if (_showCurrentTrack)
        {
            [OAGPXDocument fillWpt:item.point.wpt usingWpt:item.point];
            [_savingHelper saveWpt:item.point];
        }
    }

    if (!_showCurrentTrack)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
        [_mapViewController updateWpts:items docPath:path updateMap:NO];
    }
    
    _waypointsController.allGroups = [self readGroups];
    [_waypointsController generateData];
    [self editClicked:nil];
}

#pragma mark - OAEditGPXColorViewControllerDelegate
-(void) trackColorChanged
{
    if (_trackColorController.colorIndex == NSNotFound)
        return;
    OAGPXTrackColor *gpxColor = [[_gpxColorCollection getAvailableGPXColors] objectAtIndex:_trackColorController.colorIndex];
    _gpx.color = gpxColor.colorValue;
    [[OAGPXDatabase sharedDb] save];
    [[_app mapSettingsChangeObservable] notifyEvent];
    [self.tableView reloadData];
}

#pragma mark - OAEditColorViewControllerDelegate

-(void)colorChanged
{
    NSArray *items = [_waypointsController getSelectedItems];
    OAFavoriteColor *favCol = [[OADefaultFavorite builtinColors] objectAtIndex:_colorController.colorIndex];
    
    for (OAGpxWptItem *item in items)
    {
        item.color = favCol.color;
        
        if (_showCurrentTrack)
        {
            [OAGPXDocument fillWpt:item.point.wpt usingWpt:item.point];
            [_savingHelper saveWpt:item.point];
        }
    }
    
    if (!_showCurrentTrack)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
        [_mapViewController updateWpts:items docPath:path updateMap:YES];
    }
    else
    {
        // update map
        [[_app trackRecordingObservable] notifyEvent];        
    }
    
    [_waypointsController generateData];
    [self editClicked:nil];
}

#pragma mark - OAGPXWptListViewControllerDelegate

-(void)callGpxEditMode
{
    if (self.delegate)
        [self.delegate requestHeaderOnlyMode];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSString* newName = [alertView textFieldAtIndex:0].text;
        if (newName.length > 0)
        {
            NSString *oldFileName = self.gpx.gpxFileName;
            self.gpx.gpxTitle = newName;
            self.gpx.gpxFileName = [self.gpx.gpxTitle stringByAppendingPathExtension:@"gpx"];
            [[OAGPXDatabase sharedDb] save];
            
            OAGpxMetadata *metadata;
            if (self.doc.metadata)
            {
                metadata = (OAGpxMetadata *)self.doc.metadata;
            }
            else
            {
                metadata = [[OAGpxMetadata alloc] init];
                long time = 0;
                if (self.doc.locationMarks.count > 0)
                {
                    time = ((OAGpxWpt *)self.doc.locationMarks[0]).time;
                }
                if (self.doc.tracks.count > 0)
                {
                    OAGpxTrk *track = self.doc.tracks[0];
                    track.name = newName;
                    if (track.segments.count > 0)
                    {
                        OAGpxTrkSeg *seg = track.segments[0];
                        if (seg.points.count > 0)
                        {
                            OAGpxTrkPt *p = seg.points[0];
                            if (time > p.time)
                                time = p.time;
                        }
                    }
                }
                
                if (time == 0)
                    metadata.time = (long)[[NSDate date] timeIntervalSince1970];
                else
                    metadata.time = time;
            }
            
            metadata.name = newName;
            
            NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFileName];
            if ([NSFileManager.defaultManager fileExistsAtPath:self.doc.fileName])
                [NSFileManager.defaultManager removeItemAtPath:self.doc.fileName error:nil];
            
            BOOL saveFailed = ![_mapViewController updateMetadata:metadata oldPath:self.doc.fileName docPath:path];
            self.doc.fileName = path;
            self.doc.metadata = metadata;
            
            if (saveFailed)
                [self.doc saveTo:path];
            
            [OASelectedGPXHelper renameVisibleTrack:oldFileName newName:path.lastPathComponent];
            
            self.titleView.text = newName;
            if (self.delegate)
                [self.delegate contentChanged];
        }
    }
}

@end
