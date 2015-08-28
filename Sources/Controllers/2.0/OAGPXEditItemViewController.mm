//
//  OAGPXEditItemViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXEditItemViewController.h"
#import "OAGPXDetailsTableViewCell.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "PXAlertView.h"
#import "OADefaultFavorite.h"
#import "OAGPXEditWptListViewController.h"

#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"
#import "OAGpxWptItem.h"
#import "OAGPXRouter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


@implementation OAGPXEditItemViewControllerState
@end


@interface OAGPXEditItemViewController ()<OAGPXEditWptListViewControllerDelegate, UIAlertViewDelegate>
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
        self.gpx = gpxItem;
        [self loadDoc];
    }
    return self;
}

- (id)initWithGPXItem:(OAGPX *)gpxItem ctrlState:(OAGPXEditItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _wasInit = NO;
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
        _savingHelper = [OASavingTrackHelper sharedInstance];
        
        [self updateCurrentGPXData];
        
        _showCurrentTrack = YES;
    }
    return self;
}

- (id)initWithCurrentGPXItem:(OAGPXEditItemViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
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
            if ([settings.mapSettingVisibleGpx containsObject:self.gpx.gpxFileName]) {
                [settings hideGpx:self.gpx.gpxFileName];
                [_mapViewController hideTempGpxTrack];
                [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
            }
            
            [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFileName];
            [[OAGPXDatabase sharedDb] save];
        }
    }
    else
    {
        if (self.gpx.newGpx)
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"create_new_trip") message:OALocalizedString(@"gpx_enter_new_name \"%@\"", self.gpx.gpxTitle) delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles: OALocalizedString(@"shared_string_ok"), nil];
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
        [_mapViewController hideTempGpxTrack];
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
    //
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
    return 160.0;
}

- (void)applyLocalization
{
    [self.buttonCancel setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [self.buttonCancel setImage:[UIImage imageNamed:@"menu_icon_back"] forState:UIControlStateNormal];
    [self.buttonCancel setTintColor:[UIColor whiteColor]];
    self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0);
    self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0);
}

- (void)viewDidLoad
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

- (void)didReceiveMemoryWarning
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

- (void)closePointsController
{
    if (_waypointsController)
    {
        [_waypointsController resetData];
        [_waypointsController doViewDisappear];
        _waypointsController = nil;
    }
}

- (void)updateMap
{
    [[OARootViewController instance].mapPanel displayGpxOnMap:self.gpx];
}


#pragma mark - OAGPXEditWptListViewControllerDelegate

-(void)callGpxEditMode
{
    if (self.delegate)
        [self.delegate requestHeaderOnlyMode];
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
        [self.doc saveTo:self.doc.fileName];
    }
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
            
            
            [_mapViewController hideTempGpxTrack];

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

