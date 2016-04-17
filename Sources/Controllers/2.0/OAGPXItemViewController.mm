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
#import "OAGPXMutableDocument.h"
#import "PXAlertView.h"
#import "OAEditGroupViewController.h"
#import "OAEditColorViewController.h"
#import "OADefaultFavorite.h"
#import "OAGPXRouter.h"

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


@interface OAGPXItemViewController ()<UIDocumentInteractionControllerDelegate, OAEditGroupViewControllerDelegate, OAEditColorViewControllerDelegate, OAGPXWptListViewControllerDelegate, UIAlertViewDelegate> {

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
    NSInteger _speedSectionIndex;
    NSInteger _timeSectionIndex;
    NSInteger _uphillsSectionIndex;
    
    NSString *_exportFileName;
    NSString *_exportFilePath;

    NSArray* _groups;
    
    OAEditGroupViewController *_groupController;
    OAEditColorViewController *_colorController;
    
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

-(BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;
{
    return YES;//isViewVisible;
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
    
    if (_sectionsCount == 0)
        h = _headerView.bounds.size.height;
    
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
    
    BOOL uphillsDataExists = (self.gpx.avgElevation != 0.0 || self.gpx.minElevation != 0.0 || self.gpx.maxElevation != 0.0 || self.gpx.diffElevationDown != 0.0 || self.gpx.diffElevationUp != 0.0);
    
    NSInteger nextSectionIndex = 0;
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

    if (_sectionsCount == 0)
    {
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _tableView.frame.size.width, 100.0)];
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:_headerView.bounds];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:19.0];
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

    [self updateEditingMode:NO animated:NO];

    [self.segmentView setSelectedSegmentIndex:_segmentType];
    [self applySegmentType];
    [self resetSortModeIfNeeded];
    [self addBadge];

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
    badgeLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
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

            _waypointsController.view.frame = self.tableView.frame;
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
                                    otherTitles:@[OALocalizedString(@"fav_rename"), (self.showCurrentTrack ? OALocalizedString(@"track_clear") : OALocalizedString(@"shared_string_remove")), OALocalizedString(@"gpx_export"), OALocalizedString(@"gpx_edit_mode")]
                                      otherDesc:nil
                                    otherImages:@[@"ic_dialog_rename.png", @"track_clear_data.png", @"ic_dialog_export.png", @"ic_dialog_edit.png"]
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
    [self updateEditingMode:self.editing animated:YES];
}

- (void)updateEditingMode:(BOOL)value animated:(BOOL)animated
{
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
        f.origin.y = cs.height - f.size.height;
        
        [UIView animateWithDuration:(animated ? .3 : 0.0) animations:^{
            self.editToolbarView.frame = f;
            _waypointsController.view.frame = CGRectMake(0.0, 0.0, cs.width, cs.height - f.size.height);
        }];
    }
    else
    {
        CGSize cs = self.contentView.bounds.size;
        CGRect f = self.editToolbarView.frame;
        f.origin.y = cs.height + 1.0;
        
        [UIView animateWithDuration:(animated ? .3 : 0.0) animations:^{
            self.editToolbarView.frame = f;
            _waypointsController.view.frame = self.contentView.bounds;
        }];
    }
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
                                             [settings hideGpx:self.gpx.gpxFileName];
                                             [_mapViewController hideTempGpxTrack];
                                             [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
                                         }
                                         
                                         [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
                                         [[OAGPXDatabase sharedDb] save];
                                     }
                                     
                                     [self okPressed];
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
    if (section == _speedSectionIndex)
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
            self.gpx.gpxTitle = newName;
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
            [_mapViewController updateMetadata:metadata docPath:path];
            
            self.titleView.text = newName;
            if (self.delegate)
                [self.delegate contentChanged];
        }
    }
}

@end
