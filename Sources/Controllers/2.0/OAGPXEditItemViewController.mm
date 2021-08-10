//
//  OAGPXEditItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXEditItemViewController.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "PXAlertView.h"
#import "OADefaultFavorite.h"
#import "OAGPXEditWptListViewController.h"
#import "OAEditColorViewController.h"
#import "OASelectedGPXHelper.h"

#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"
#import "OAGpxWptItem.h"
#import "OAGPXRouter.h"
#import "OAGPXItemViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


@implementation OAGPXEditItemViewControllerState
@end


@interface OAGPXEditItemViewController ()<OAGPXEditWptListViewControllerDelegate, UIAlertViewDelegate, OAEditColorViewControllerDelegate>
{
    OsmAndAppInstance _app;
    
    OAMapViewController *_mapViewController;
    
    CGFloat _scrollPos;
    BOOL _wasInit;
    BOOL _cancelPressed;
}

@property (nonatomic) OAGPXDocument *doc;

@end

@implementation OAGPXEditItemViewController
{
    OASavingTrackHelper *_savingHelper;
    OAGPXEditWptListViewController *_waypointsController;

    OAEditColorViewController *_colorController;
    CALayer *_horizontalLine;
    
    OAGPXEditItemViewControllerState *_ctrlState;
    
    BOOL _localEditing;
}

@synthesize editing = _editing;
@synthesize wasEdited = _wasEdited;
@synthesize showingKeyboard = _showingKeyboard;

- (id) initWithGPXItem:(OAGPX *)gpxItem
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _wasInit = NO;
        _scrollPos = 0.0;
        self.gpx = gpxItem;
        [self loadDoc];
    }
    return self;
}

- (id) initWithGPXItem:(OAGPX *)gpxItem ctrlState:(OAGPXEditItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _wasInit = NO;
        _scrollPos = ctrlState.scrollPos;
        _ctrlState = ctrlState;
        self.gpx = gpxItem;
        [self loadDoc];
    }
    return self;
}

- (id) initWithCurrentGPXItem
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
    }
    return self;
}

- (id) initWithCurrentGPXItem:(OAGPXEditItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        _scrollPos = ctrlState.scrollPos;
        _ctrlState = ctrlState;
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
    }
    return self;
}

- (BOOL) hasRouteButton
{
    return NO;
}

- (BOOL)denyClose
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (NSAttributedString *) getAttributedTypeStr
{
    return [OAGPXItemViewController getAttributedTypeStr:self.gpx];
}

- (void) updateCurrentGPXData
{
    OAGPX* item = [_savingHelper getCurrentGPX];
    item.gpxTitle = OALocalizedString(@"track_recording_name");
    
    self.gpx = item;
    self.doc = (OAGPXDocument*)_savingHelper.currentTrack;
}

- (void) loadDoc
{
    OAGPXRouter *gpxRouter = [OAGPXRouter sharedInstance];
    if (gpxRouter.gpx && [gpxRouter.gpx.gpxFilePath isEqualToString:self.gpx.gpxFilePath])
        [gpxRouter cancelRoute];
    
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath];
    self.doc = [[OAGPXDocument alloc] initWithGpxFile:path];
}

- (void) cancelPressed
{
    _cancelPressed = YES;
    
    if (self.gpx.newGpx && self.gpx.wptPoints == 0)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        
        if (self.showCurrentTrack)
        {
            settings.mapSettingTrackRecording = NO;
            [[OASavingTrackHelper sharedInstance] clearData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mapViewController hideRecGpxTrack];
            });
        }
        else
        {
            if ([settings.mapSettingVisibleGpx.get containsObject:self.gpx.gpxFilePath]) {
                [settings hideGpx:@[self.gpx.gpxFilePath]];
                [_mapViewController hideTempGpxTrack];
                [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
            }
            
            [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFilePath];
            [[OAGPXDatabase sharedDb] save];
        }
    }
    else
    {
        if (self.gpx.newGpx)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"create_new_trip") message:OALocalizedString(@"gpx_enter_new_name \"%@\"", self.gpx.gpxTitle) delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles: OALocalizedString(@"shared_string_save"), OALocalizedString(@"shared_string_delete"), nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert textFieldAtIndex:0].text = self.gpx.gpxTitle;
            [alert show];
            return;
        }
    }
    
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
    if (!self.gpx.newGpx || self.gpx.wptPoints > 0 || self.gpx.points > 0)
    {
        [_mapViewController keepTempGpxTrackVisible];
        [self closePointsController];
    }
    
    return YES;
}

-(BOOL)disablePanWhileEditing
{
    return YES;
}

-(BOOL)supportEditing
{
    return NO;
}

- (void)activateEditing
{
}

-(BOOL)showTopControls
{
    return YES;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

-(BOOL)supportFullMenu
{
    return NO;
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

- (CGFloat) contentHeight
{
    return 160.0;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    self.titleView.text = [self.gpx getNiceTitle];
    
    _waypointsController = [[OAGPXEditWptListViewController alloc] initWithLocationMarks:self.doc.locationMarks];
    _waypointsController.delegate = self;
    _waypointsController.view.frame = self.contentView.bounds;
    [_waypointsController doViewAppear];
    [self.contentView addSubview:_waypointsController.view];
    
    
    if (!_wasInit && _scrollPos != 0.0)
        [_waypointsController.tableView setContentOffset:CGPointMake(0.0, _scrollPos)];
    
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
            [_mapViewController showTempGpxTrack:self.gpx.gpxFilePath];
        });
    }

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.editToolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.editToolbarView.layer addSublayer:_horizontalLine];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, 0.5);
    
    [self updateWaypointsButtons];
    [self updateButtonsLayout];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (OATargetMenuViewControllerState *) getCurrentState
{
    OAGPXEditItemViewControllerState *state = [[OAGPXEditItemViewControllerState alloc] init];
    state.scrollPos = _waypointsController.tableView.contentOffset.y;
    
    return state;
}

-(void) goHeaderOnly
{
    [self updateButtonsLayout];
}

-(void) goFullScreen
{
    [self updateButtonsLayout];
}

- (void) closePointsController
{
    if (_waypointsController)
    {
        [_waypointsController resetData];
        [_waypointsController doViewDisappear];
        _waypointsController = nil;
    }
}

- (void) updateMap
{
    [[OARootViewController instance].mapPanel displayGpxOnMap:self.gpx];
}

- (IBAction) buttonMapClicked:(id)sender
{
    if (self.delegate)
    {
        if (![self.delegate isInFullScreenMode])
            [self callFullScreenMode];
        else
            [self callGpxEditMode];
    }
}

-(IBAction)buttonEditClicked:(id)sender
{
    _localEditing = !_localEditing;
    [self updateEditingMode:_localEditing animated:YES];
}

- (void)updateButtonsLayout
{
    BOOL isInFullScreenMode = NO;
    if (self.delegate)
        isInFullScreenMode = [self.delegate isInFullScreenMode];
    else if (_ctrlState)
        isInFullScreenMode = _ctrlState.showFullScreen;
    
    if (isInFullScreenMode)
    {
        [self.buttonMap setImage:[UIImage imageNamed:@"left_menu_icon_map.png"] forState:UIControlStateNormal];
        self.buttonMap.frame = CGRectMake(DeviceScreenWidth - 80.0, OAUtilities.getStatusBarHeight, 35.0, 44.0);
        self.buttonMap.hidden = NO;
        self.buttonEdit.hidden = NO;
    }
    else
    {
        [self.buttonMap setImage:[UIImage imageNamed:@"ic_list.png"] forState:UIControlStateNormal];
        self.buttonMap.frame = self.buttonEdit.frame;
        self.buttonEdit.hidden = YES;
        self.buttonMap.hidden = NO;
    }
}

- (void)updateWaypointsButtons
{
    self.buttonEdit.hidden = NO;
    if (_localEditing)
        [self.buttonEdit setImage:[UIImage imageNamed:@"icon_edit_active"] forState:UIControlStateNormal];
    else
        [self.buttonEdit setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
    
    NSInteger wptCount = self.doc.locationMarks.count;
    self.buttonEdit.enabled = wptCount > 0;
}

- (void)updateEditingMode:(BOOL)value animated:(BOOL)animated
{
    if (value)
        [self callFullScreenMode];
    
    [_waypointsController setLocalEditing:value];
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

- (IBAction)waypointsColorClicked:(id)sender
{
    [self changeColor];
}

- (IBAction)waypointsDeleteClicked:(id)sender
{
    [self deleteWaypoints];
}

- (void)changeColor
{
    NSArray *selectedRows = [_waypointsController getSelectedItems];
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
    NSArray *selectedRows = [_waypointsController getSelectedItems];
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
                                     NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath];
                                     [_mapViewController deleteWpts:items docPath:path];
                                     [self loadDoc];
                                 }
                                 
                                 [_waypointsController setPoints:self.doc.locationMarks];
                                 [_waypointsController generateData];
                                 [self buttonEditClicked:nil];
                                 if (self.delegate)
                                     [self.delegate contentChanged];
                             }
                         }];
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
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath];
        [_mapViewController updateWpts:items docPath:path updateMap:YES];
    }
    else
    {
        // update map
        [[_app trackRecordingObservable] notifyEvent];
    }
    
    [_waypointsController generateData];
    [self buttonEditClicked:nil];
}

#pragma mark - OAGPXEditWptListViewControllerDelegate

-(void)callGpxEditMode
{
    if (self.delegate)
        [self.delegate requestHeaderOnlyMode];
}

- (void)callFullScreenMode
{
    if (self.delegate)
        [self.delegate requestFullScreenMode];
}

-(void)refreshGpxDocWithPoints:(NSArray *)points
{
    if (_showCurrentTrack)
    {
        [_savingHelper deleteAllWpts];
        
        for (OAGpxWpt *wpt in points)
            [_savingHelper addWpt:wpt];
    }
    else
    {
        self.doc.locationMarks = points;
        [self.doc saveTo:self.doc.path];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        if (buttonIndex == 1)
        {
            NSString* newName = [alertView textFieldAtIndex:0].text;
            if (newName.length > 0)
            {
                NSString *oldFileName = self.gpx.gpxFileName;
                NSString *oldFilePath = self.gpx.gpxFilePath;
                NSString *oldPath = [_app.gpxPath stringByAppendingPathComponent:oldFilePath];
                self.gpx.gpxTitle = newName;
                self.gpx.gpxFileName = [newName stringByAppendingPathExtension:@"gpx"];
                self.gpx.gpxFilePath = [[self.gpx.gpxFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:self.gpx.gpxFileName];
                NSString *newPath = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath];
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
                
                
                if ([NSFileManager.defaultManager fileExistsAtPath:self.doc.path])
                    [NSFileManager.defaultManager removeItemAtPath:self.doc.path error:nil];
                
                BOOL saveFailed = ![_mapViewController updateMetadata:metadata oldPath:oldPath docPath:newPath];
                self.doc.path = newPath;
                self.doc.metadata = metadata;
                
                if (saveFailed)
                    [self.doc saveTo:newPath];
                
                [OASelectedGPXHelper renameVisibleTrack:oldFilePath newPath:self.gpx.gpxFilePath];
                
                [_mapViewController hideTempGpxTrack];
                
                if (self.delegate)
                    [self.delegate btnCancelPressed];
                
                [self closePointsController];
            }
        }
        else
        {
            OAAppSettings *settings = [OAAppSettings sharedManager];
            
            if (self.showCurrentTrack)
            {
                settings.mapSettingTrackRecording = NO;
                [[OASavingTrackHelper sharedInstance] clearData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_mapViewController hideRecGpxTrack];
                });
            }
            else
            {
                if ([settings.mapSettingVisibleGpx.get containsObject:self.gpx.gpxFilePath]) {
                    [settings hideGpx:@[self.gpx.gpxFilePath]];
                    [_mapViewController hideTempGpxTrack];
                    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
                }
                
                [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFilePath];
                [[OAGPXDatabase sharedDb] save];
            }
            
            if (self.delegate)
                [self.delegate btnCancelPressed];
            
            [self closePointsController];

        }
    }
    else
    {
        _cancelPressed = NO;
    }
}

@end

