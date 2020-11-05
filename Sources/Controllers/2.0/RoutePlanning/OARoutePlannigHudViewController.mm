//
//  OARoutePlannigHudViewController.m
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoutePlannigHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAColors.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "Localization.h"
#import "OAMeasurementCommandManager.h"
#import "OAAddPointCommand.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OAGPXDocumentPrimitives.h"
#import "OALocationServices.h"
#import "OAGpxData.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDatabase.h"
#import "OAReorderPointCommand.h"
#import "OARemovePointCommand.h"
#import "OAPointOptionsBottomSheetViewController.h"
#import "OAInfoBottomView.h"
#import "OAMovePointCommand.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

#define kDefaultMapRulerMarginBottom -17.0
#define kDefaultMapRulerMarginLeft 120.0

typedef NS_ENUM(NSInteger, EOAFinalSaveAction) {
    SHOW_SNACK_BAR_AND_CLOSE = 0,
    SHOW_TOAST,
    SHOW_IS_SAVED_FRAGMENT
};

typedef NS_ENUM(NSInteger, EOASaveType) {
    ROUTE_POINT = 0,
    LINE
};

typedef NS_ENUM(NSInteger, EOAHudMode) {
    EOAHudModeRoutePlanning = 0,
    EOAHudModeMovePoint
};

@interface OARoutePlannigHudViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, OAMeasurementLayerDelegate, OAPointOptionsBottmSheetDelegate, OAInfoBottomViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *centerImageView;
@property (weak, nonatomic) IBOutlet UIView *closeButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIButton *undoButton;
@property (weak, nonatomic) IBOutlet UIButton *redoButton;
@property (weak, nonatomic) IBOutlet UIButton *addPointButton;
@property (weak, nonatomic) IBOutlet UIButton *expandButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftImageVIew;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation OARoutePlannigHudViewController
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    OAMapPanelViewController *_mapPanel;
    OAMeasurementToolLayer *_layer;
    
    OAMeasurementEditingContext *_editingContext;
    
    CGFloat _cachedYViewPort;
    
    EOAHudMode _hudMode;
    
    OAInfoBottomView *_infoView;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OARoutePlannigHudViewController"
                           bundle:nil];
    if (self)
    {
        _app = OsmAndApp.instance;
        _settings = [OAAppSettings sharedManager];
        _mapPanel = OARootViewController.instance.mapPanel;
        _layer = _mapPanel.mapViewController.mapLayers.routePlanningLayer;
        // TODO: port later public void openPlanRoute()
        _editingContext = [[OAMeasurementEditingContext alloc] init];
        
        _layer.editingCtx = _editingContext;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hudMode = EOAHudModeRoutePlanning;
    
    [_optionsButton setTitle:OALocalizedString(@"shared_string_options") forState:UIControlStateNormal];
    [_addPointButton setTitle:OALocalizedString(@"add_point") forState:UIControlStateNormal];
    _expandButton.imageView.tintColor = UIColorFromRGB(color_icon_inactive);
    [_expandButton setImage:[[UIImage imageNamed:@"ic_custom_arrow_up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [_undoButton setImage:[[UIImage imageNamed:@"ic_custom_undo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_redoButton setImage:[[UIImage imageNamed:@"ic_custom_redo"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    _undoButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    _redoButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setEditing:YES];
    [self updateDistancePointsText];
    [self show:YES state:EOADraggableMenuStateInitial onComplete:nil];
//    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    [_mapPanel setTopControlsVisible:NO customStatusBarStyle:UIStatusBarStyleLightContent];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:self.getViewHeight animated:YES];
    _centerImageView.image = [UIImage imageNamed:@"ic_ruler_center.png"];
    [self changeCenterOffset:[self getViewHeight]];
    
    _closeButtonContainerView.layer.cornerRadius = 12.;
    _doneButtonContainerView.layer.cornerRadius = 12.;
    
    [_closeButton setImage:[[UIImage imageNamed:@"ic_navbar_close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    _closeButton.imageView.tintColor = UIColor.whiteColor;
    
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    _titleView.text = OALocalizedString(@"plan_route");
    
    _layer.delegate = self;
    
    [self adjustMapViewPort];
    [self changeMapRulerPosition];
    
    self.tableView.userInteractionEnabled = YES;
    [self.view bringSubviewToFront:self.tableView];
}

- (BOOL)supportsFullScreen
{
    return NO;
}

- (CGFloat)initialMenuHeight
{
    return _hudMode == EOAHudModeRoutePlanning ? 60. + self.toolBarView.frame.size.height : 240.;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)useGestureRecognizer
{
    return NO;
}

- (CGFloat) additionalLandscapeOffset
{
    return 100.;
}

- (void) changeMapRulerPosition
{
    CGFloat bottomMargin = OAUtilities.isLandscapeIpadAware ? kDefaultMapRulerMarginBottom : (-self.getViewHeight + OAUtilities.getBottomMargin - 25.);
    CGFloat leftMargin = OAUtilities.isLandscapeIpadAware ? self.scrollableView.frame.size.width - OAUtilities.getLeftMargin + 16.0 : kDefaultMapRulerMarginLeft;
    [_mapPanel targetSetMapRulerPosition:bottomMargin left:leftMargin];
}

- (void) changeCenterOffset:(CGFloat)contentHeight
{
    if (OAUtilities.isLandscapeIpadAware)
    {
        _centerImageView.center = CGPointMake(DeviceScreenWidth * 0.75,
                                        self.view.frame.size.height * 0.5);
    }
    else
    {
        _centerImageView.center = CGPointMake(self.view.frame.size.width * 0.5,
                                        self.view.frame.size.height * 0.5 - contentHeight / 2);
    }
}

- (void)adjustMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if ([OAUtilities isLandscapeIpadAware])
    {
        mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
        mapView.viewportYScale = VIEWPORT_NON_SHIFTED_SCALE;
    }
    else
    {
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
        mapView.viewportYScale = self.getViewHeight / DeviceScreenHeight;
    }
}

- (void) restoreMapViewPort
{
    OAMapRendererView *mapView = [OARootViewController instance].mapPanel.mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != _cachedYViewPort)
        mapView.viewportYScale = _cachedYViewPort;
}

- (void) updateDistancePointsText
{
    if (_layer != nil)
    {
        NSString *distanceStr = [_app getFormattedDistance:_editingContext.getRouteDistance];
        self.titleLabel.text = [NSString stringWithFormat:@"%@, %@ %ld", distanceStr, OALocalizedString(@"points_count"), _editingContext.getPointsCount];
    }
}


- (IBAction)closePressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [_mapPanel targetSetMapRulerPosition:kDefaultMapRulerMarginBottom left:kDefaultMapRulerMarginLeft];
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
        _layer.editingCtx = nil;
        [_layer resetLayer];
    }];
}

- (IBAction)donePressed:(id)sender
{
//    if ([self isFollowTrackMode])
//        [self startTrackNavigation];
//    else
    [self saveChanges:SHOW_SNACK_BAR_AND_CLOSE showDialog:NO];
    [self hide:YES duration:.2 onComplete:^{
        [_mapPanel targetSetMapRulerPosition:kDefaultMapRulerMarginBottom left:kDefaultMapRulerMarginLeft];
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
        _layer.editingCtx = nil;
        [_layer resetLayer];
    }];
}

- (IBAction)onExpandButtonPressed:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *button = (UIButton *) sender;
        if (self.currentState == EOADraggableMenuStateInitial)
        {
            [self goExpanded];
            [button setImage:[[UIImage imageNamed:@"ic_custom_arrow_down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else
        {
            [self goMinimized];
            [button setImage:[[UIImage imageNamed:@"ic_custom_arrow_up"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
    }
}
- (IBAction)onOptionsButtonPressed:(id)sender
{
}

- (IBAction)onUndoButtonPressed:(id)sender
{
    [_editingContext.commandManager undo];
    [self onPointsListChanged];
}

- (IBAction)onRedoButtonPressed:(id)sender
{
    [_editingContext.commandManager redo];
    [self onPointsListChanged];
}

- (IBAction)onAddPointPressed:(id)sender
{
    [self addCenterPoint];
}

- (NSString *) getSuggestedFileName
{
    OAGpxData *gpxData = _editingContext.gpxData;
    NSString *displayedName = nil;
//    if (gpxData != nil) {
//        OAGPXDocument *gpxFile = gpxData.gpxFile;
//        if (!Algorithms.isEmpty(gpxFile.path)) {
//            displayedName = Algorithms.getFileNameWithoutExtension(new File(gpxFile.path).getName());
//        } else if (!Algorithms.isEmpty(gpxFile.tracks)) {
//            displayedName = gpxFile.tracks.get(0).name;
//        }
//    }
    if (gpxData == nil || displayedName == nil)
    {
        NSDateFormatter *objDateFormatter = [[NSDateFormatter alloc] init];
        [objDateFormatter setDateFormat:@"EEE dd MMM yyyy"];
        NSString *suggestedName = [objDateFormatter stringFromDate:[NSDate date]];
        displayedName = [self createUniqueFileName:suggestedName];
    }
//    else
//    {
//        displayedName = Algorithms.getFileNameWithoutExtension(new File(gpxData.getGpxFile().path).getName());
//    }
    return displayedName;
}

- (NSString *) createUniqueFileName:(NSString *)fileName
{
    NSString *path = [[_app.gpxPath stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"gpx"];
    NSFileManager *fileMan = [NSFileManager defaultManager];
    if ([fileMan fileExistsAtPath:path])
    {
        NSString *ext = [fileName pathExtension];
        NSString *newName;
        for (int i = 2; i < 100000; i++) {
            newName = [[NSString stringWithFormat:@"%@_(%d)", [fileName stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
            path = [_app.gpxPath stringByAppendingPathComponent:newName];
            if (![fileMan fileExistsAtPath:path])
                break;
        }
        return [newName stringByDeletingPathExtension];
    }
    return fileName;
}

- (void) saveChanges:(EOAFinalSaveAction)finalSaveAction showDialog:(BOOL)showDialog
{
    
    if (_editingContext.getPointsCount > 0)
    {
//        OAGpxData *gpxData = _editingContext.gpxData;
        if ([_editingContext isNewData] /*|| (isInEditMode() && gpxData.getActionType() == ActionType.EDIT_SEGMENT)*/)
        {
//            if (showDialog) {
//                openSaveAsNewTrackMenu(mapActivity);
//            } else {
            [self saveNewGpx:nil fileName:[self getSuggestedFileName] showOnMap:YES simplifiedTrack:YES finalSaveAction:finalSaveAction];
        }
//        } else {
//            addToGpx(mapActivity, finalSaveAction);
//        }
    }
//    else
//        Toast.makeText(mapActivity, getString(R.string.none_point_error), Toast.LENGTH_SHORT).show();
}

- (void) saveNewGpx:(NSString *)folderName fileName:(NSString *)fileName showOnMap:(BOOL)showOnMap
    simplifiedTrack:(BOOL)simplifiedTrack finalSaveAction:(EOAFinalSaveAction)finalSaveAction
{
    NSString *gpxPath = _app.gpxPath;
    if (folderName != nil && ![gpxPath.lastPathComponent isEqualToString:folderName])
        gpxPath = [gpxPath stringByAppendingPathComponent:folderName];
    fileName = [fileName stringByAppendingPathExtension:@"gpx"];
    EOASaveType saveType = simplifiedTrack ? LINE : ROUTE_POINT;
    [self saveNewGpx:gpxPath fileName:fileName showOnMap:showOnMap saveType:saveType finalSaveAction:finalSaveAction];
}

- (void) saveNewGpx:(NSString *)dir fileName:(NSString *)fileName showOnMap:(BOOL)showOnMap saveType:(EOASaveType)saveType finalSaveAction:(EOAFinalSaveAction)finalSaveAction
{
    [self saveGpx:[dir stringByAppendingPathComponent:fileName] gpxFile:nil actionType:UNDEFINED saveType:saveType finalSaveAction:finalSaveAction showOnMap:showOnMap];
}

- (void) saveGpx:(NSString *)outFile gpxFile:(OAGPXDocument *)gpxFile actionType:(EOAActionType)actionType
saveType:(EOASaveType)saveType finalSaveAction:(EOAFinalSaveAction)finalSaveAction showOnMap:(BOOL)showOnMap
{
//        SaveGpxRouteListener saveGpxRouteListener = new SaveGpxRouteListener() {
//            @Override
//            public void gpxSavingFinished(Exception warning, GPXFile savedGpxFile, File backupFile) {
//                onGpxSaved(warning, savedGpxFile, outFile, backupFile, actionType, finalSaveAction, showOnMap);
//            }
//        };
    [self saveGpxRoute:outFile gpxFile:gpxFile actionType:actionType saveType:saveType showOnMap:showOnMap onComplete:^(OAGPXDocument * gpx, NSString *) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"File saved to %@", gpx.fileName]  preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
        });
    }];
}

- (void) saveGpxRoute:(NSString *)outFile gpxFile:(OAGPXDocument *)gpxFile actionType:(EOAActionType)actionType saveType:(EOASaveType)saveType showOnMap:(BOOL)showOnMap
           onComplete:(void(^)(OAGPXDocument *, NSString *))onComplete
{
    OARoutePlannigHudViewController * __weak weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (weakSelf == nil)
            return;
        NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_editingContext.getPoints];
        OATrackSegment *before = _editingContext.getBeforeTrkSegmentLine;
        OATrackSegment *after = _editingContext.getAfterTrkSegmentLine;
        if (gpxFile == nil)
        {
            NSString *fileName = outFile.lastPathComponent;
            NSString *trackName = [fileName stringByReplacingOccurrencesOfString:@".gpx" withString:@""];
            OAGPXMutableDocument *gpx = [[OAGPXMutableDocument alloc] init];
            if (saveType == LINE)
            {
                OAGpxTrkSeg *segment = [[OAGpxTrkSeg alloc] init];
//                if (_editingContext.hasRoute)
//                {
//                    segment.points = [NSArray arrayWithArray:_editingContext.getRoutePoints];
//                }
//                else
//                {
                NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:before.points];
                [points addObjectsFromArray:after.points];
                segment.points = [NSArray arrayWithArray:points];
//                }
                OAGpxTrk *track = [[OAGpxTrk alloc] init];
                track.name = trackName;
                track.segments = @[segment];
                [gpx addTrack:track];
            }
            else if (saveType == ROUTE_POINT)
            {
//                if (_editingContext.hasRoute)
//                {
//                    GPXFile newGpx = editingCtx.exportRouteAsGpx(trackName);
//                    if (newGpx != null) {
//                        gpx = newGpx;
//                    }
//                }
                NSMutableArray *rtePoints = [NSMutableArray new];
                for (OAGpxTrkPt *pt in points)
                {
                    [rtePoints addObject:[[OAGpxRtePt alloc] initWithTrkPt:pt]];
                }
                [gpx addRoutePoints:rtePoints];
            }
            gpx.fileName = fileName;
            [gpx saveTo:outFile];
            OAGPXTrackAnalysis *analysis = [gpx getAnalysis:0];
            [[OAGPXDatabase sharedDb] addGpxItem:[outFile lastPathComponent] title:gpx.metadata.name desc:gpx.metadata.desc bounds:gpx.bounds analysis:analysis];
            [[OAGPXDatabase sharedDb] save];
            if (showOnMap)
            {
                [self showGpxOnMap:gpx actionType:actionType isNewGpx:YES];
            }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                onComplete(gpx, outFile);
            });
        }
//        else {
//                    GPXFile gpx = gpxFile;
//                    backupFile = FileUtils.backupFile(app, outFile);
//                    String trackName = Algorithms.getFileNameWithoutExtension(outFile);
//                    if (measurementLayer != null) {
//                        if (fragment.isPlanRouteMode()) {
//                            if (saveType == MeasurementToolFragment.SaveType.LINE) {
//                                TrkSegment segment = new TrkSegment();
//                                if (editingCtx.hasRoute()) {
//                                    segment.points.addAll(editingCtx.getRoutePoints());
//                                } else {
//                                    segment.points.addAll(before.points);
//                                    segment.points.addAll(after.points);
//                                }
//                                Track track = new Track();
//                                track.name = trackName;
//                                track.segments.add(segment);
//                                gpx.tracks.add(track);
//                            } else if (saveType == MeasurementToolFragment.SaveType.ROUTE_POINT) {
//                                if (editingCtx.hasRoute()) {
//                                    GPXFile newGpx = editingCtx.exportRouteAsGpx(trackName);
//                                    if (newGpx != null) {
//                                        gpx = newGpx;
//                                    }
//                                }
//                                gpx.addRoutePoints(points);
//                            }
//                        } else if (actionType != null) {
//                            GpxData gpxData = editingCtx.getGpxData();
//                            switch (actionType) {
//                                case ADD_SEGMENT: {
//                                    List<WptPt> snappedPoints = new ArrayList<>();
//                                    snappedPoints.addAll(before.points);
//                                    snappedPoints.addAll(after.points);
//                                    gpx.addTrkSegment(snappedPoints);
//                                    break;
//                                }
//                                case ADD_ROUTE_POINTS: {
//                                    gpx.replaceRoutePoints(points);
//                                    break;
//                                }
//                                case EDIT_SEGMENT: {
//                                    if (gpxData != null) {
//                                        TrkSegment segment = new TrkSegment();
//                                        segment.points.addAll(points);
//                                        gpx.replaceSegment(gpxData.getTrkSegment(), segment);
//                                    }
//                                    break;
//                                }
//                                case OVERWRITE_SEGMENT: {
//                                    if (gpxData != null) {
//                                        List<WptPt> snappedPoints = new ArrayList<>();
//                                        snappedPoints.addAll(before.points);
//                                        snappedPoints.addAll(after.points);
//                                        TrkSegment segment = new TrkSegment();
//                                        segment.points.addAll(snappedPoints);
//                                        gpx.replaceSegment(gpxData.getTrkSegment(), segment);
//                                    }
//                                    break;
//                                }
//                            }
//                        } else {
//                            gpx.addRoutePoints(points);
//                        }
//                    }
//                    Exception res = null;
//                    if (!gpx.showCurrentTrack) {
//                        res = GPXUtilities.writeGpxFile(outFile, gpx);
//                    }
//                    savedGpxFile = gpx;
//                    if (showOnMap) {
//                        MeasurementToolFragment.showGpxOnMap(app, gpx, actionType, false);
//                    }
//                    return res;
    });
}

- (void) showGpxOnMap:(OAGPXDocument *)gpx actionType:(EOAActionType)actionType isNewGpx:(BOOL)isNewGpx
{
    [_settings showGpx:@[gpx.fileName]];
//    if (sf != null && !isNewGpx) {
//        if (actionType == ActionType.ADD_SEGMENT || actionType == ActionType.EDIT_SEGMENT) {
//            sf.processPoints(app);
//        }
//    }
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeCenterOffset:height];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:OAUtilities.isLandscapeIpadAware ? 0. : (height - 30.) animated:YES];
    [self changeMapRulerPosition];
    [self adjustMapViewPort];
}

- (void) onPointsListChanged
{
    [self.tableView reloadData];
    [self updateDistancePointsText];
}

- (BOOL) addCenterPoint
{
    BOOL added = NO;
    if (_layer != nil) {
        added = [_editingContext.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:_layer center:YES]];
        [self onPointsListChanged];
    }
    return added;
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _editingContext.getPointsCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OAMenuSimpleCellNoIcon";
    OAMenuSimpleCellNoIcon* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
    }
    cell.textView.text = [NSString stringWithFormat:OALocalizedString(@"point_num"), indexPath.row + 1];
    
    OAGpxTrkPt *point1 = _editingContext.getPoints[indexPath.row];
    CLLocation *location1 = [[CLLocation alloc] initWithLatitude:point1.getLatitude longitude:point1.getLongitude];
    if (indexPath.row == 0)
    {
        CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
        if (currentLocation)
        {
            double azimuth = [location1 bearingTo:currentLocation];
            cell.descriptionView.text = [NSString stringWithFormat:@"%@ • %@ • %@", OALocalizedString(@"gpx_start"), [_app getFormattedDistance:[location1 distanceFromLocation:currentLocation]], [OsmAndApp.instance getFormattedAzimuth:azimuth]];
        }
        else
        {
            cell.descriptionView.text = OALocalizedString(@"gpx_start");
        }
    }
    else
    {
        OAGpxTrkPt *point2 = indexPath.row == 0 && _editingContext.getPointsCount > 1 ? _editingContext.getPoints[indexPath.row + 1] : _editingContext.getPoints[indexPath.row - 1];
        CLLocation *location2 = [[CLLocation alloc] initWithLatitude:point2.getLatitude longitude:point2.getLongitude];
        double azimuth = [location1 bearingTo:location2];
        cell.descriptionView.text = [NSString stringWithFormat:@"%@ • %@", [_app getFormattedDistance:[location1 distanceFromLocation:location2]], [OsmAndApp.instance getFormattedAzimuth:azimuth]];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [_editingContext.commandManager execute:[[OARemovePointCommand alloc] initWithLayer:_layer position:indexPath.row]];
        [tableView beginUpdates];
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
        [self updateDistancePointsText];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // Deferr the data update until the animation is complete
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [tableView reloadData];
    }];
    [_editingContext.commandManager execute:[[OAReorderPointCommand alloc] initWithLayer:_layer from:sourceIndexPath.row to:destinationIndexPath.row]];
    [self updateDistancePointsText];
    [CATransaction commit];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPointOptionsBottomSheetViewController *bottomSheet = [[OAPointOptionsBottomSheetViewController alloc] initWithPoint:_editingContext.getPoints[indexPath.row] index:indexPath.row];
    bottomSheet.delegate = self;
    [bottomSheet presentInViewController:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAMeasurementLayerDelegate

- (void)onMeasue:(double)distance bearing:(double)bearing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.descriptionLabel.text = [NSString stringWithFormat:@"%@ • %@", [_app getFormattedDistance:distance], [OsmAndApp.instance getFormattedAzimuth:bearing]];
    });
}

#pragma mark - OAPointOptionsBottmSheetDelegate

- (void)showMovingInfoView
{
    _infoView = [[OAInfoBottomView alloc] init];
    _infoView.frame = self.scrollableView.bounds;
    _infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _infoView.leftIconView.image = [UIImage imageNamed:@"ic_custom_change_object_position"];
    _infoView.titleView.text = OALocalizedString(@"move_point");
    _infoView.mainInfoLabel.text = OALocalizedString(@"move_point_descr");
    [_infoView.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_infoView.rightButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
    _infoView.layer.cornerRadius = 9.;
    _infoView.clipsToBounds = NO;
    _infoView.layer.masksToBounds = YES;
    
    _infoView.delegate = self;
    [self.scrollableView addSubview:_infoView];
    _hudMode = EOAHudModeMovePoint;
    [self goMinimized];
}

- (void) onMovePoint:(NSInteger)pointPosition
{
    [self showMovingInfoView];
    [self enterMovingMode:pointPosition];
}

- (void) enterMovingMode:(NSInteger)pointPosition
{
    _editingContext.selectedPointPosition = pointPosition;
    OAGpxTrkPt *pt = _editingContext.getPoints[pointPosition];
    _editingContext.originalPointToMove = pt;
    [_layer enterMovingPointMode];
}

#pragma mark - OAInfoBottomViewDelegate

- (void)onLeftButtonPressed
{
    [self onCloseButtonPressed];
}

- (void)onRightButtonPressed
{
    OAGpxTrkPt *newPoint = [_layer getMovedPointToApply];
    [_editingContext.commandManager execute:[[OAMovePointCommand alloc] initWithLayer:_layer oldPoint:_editingContext.originalPointToMove newPoint:newPoint position:_editingContext.selectedPointPosition]];
    
    [self onCloseButtonPressed];
}

- (void)onCloseButtonPressed
{
    _editingContext.selectedPointPosition = -1;
    _editingContext.originalPointToMove = nil;
    
    [UIView animateWithDuration:.2 animations:^{
        _infoView.alpha = 0.;
        _hudMode = EOAHudModeRoutePlanning;
        [self goMinimized];
    } completion:^(BOOL finished) {
        [_layer exitMovingMode];
        [_infoView removeFromSuperview];
        _infoView = nil;
    }];
}

@end
