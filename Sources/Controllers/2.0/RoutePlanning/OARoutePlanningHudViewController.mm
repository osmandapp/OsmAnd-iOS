//
//  OARoutePlanningHudViewController.m
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARoutePlanningHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapActions.h"
#import "OARoutingHelper.h"
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
#import "OAClearPointsCommand.h"
#import "OAReversePointsCommand.h"
#import "OASegmentOptionsBottomSheetViewController.h"
#import "OAPlanningOptionsBottomSheetViewController.h"
#import "OAExitRoutePlanningBottomSheetViewController.h"
#import "OASaveTrackBottomSheetViewController.h"
#import "OAChangeRouteModeCommand.h"
#import "OATargetPointsHelper.h"
#import "OASplitPointsCommand.h"
#import "OAJoinPointsCommand.h"
#import "OASaveGpxRouteAsyncTask.h"
#import "OASaveTrackViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OASavingTrackHelper.h"
#import "QuadRect.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

#define kDefaultMapRulerMarginBottom -17.0
#define kDefaultMapRulerMarginLeft 120.0

#define PLAN_ROUTE_MODE 0x1
#define DIRECTION_MODE 0x2
#define FOLLOW_TRACK_MODE 0x4
#define UNDO_MODE 0x8

typedef NS_ENUM(NSInteger, EOAFinalSaveAction) {
    SHOW_SNACK_BAR_AND_CLOSE = 0,
    SHOW_TOAST,
    SHOW_IS_SAVED_FRAGMENT
};

typedef NS_ENUM(NSInteger, EOAHudMode) {
    EOAHudModeRoutePlanning = 0,
    EOAHudModeMovePoint,
    EOAHudModeAddPoints
};

@interface OARoutePlanningHudViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate,
    OAMeasurementLayerDelegate, OAPointOptionsBottmSheetDelegate, OAInfoBottomViewDelegate, OASegmentOptionsDelegate, OASnapToRoadProgressDelegate, OAPlanningOptionsDelegate,
    OAOpenAddTrackDelegate, OASaveTrackViewControllerDelegate, OAExitRoutePlanningDelegate>

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
@property (weak, nonatomic) IBOutlet UIView *actionButtonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navbarLeadingConstraint;

@end

@implementation OARoutePlanningHudViewController
{
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    
    OAMapPanelViewController *_mapPanel;
    OAMeasurementToolLayer *_layer;
    
    OAMeasurementEditingContext *_editingContext;
    
    CGFloat _cachedYViewPort;
    
    EOAHudMode _hudMode;
    
    OAInfoBottomView *_infoView;
    
    int _modes;
    
    NSString *_fileName;
    CLLocation *_initialPoint;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OARoutePlanningHudViewController"
                           bundle:nil];
    if (self)
    {
        [self commonInit];
        [self setMode:PLAN_ROUTE_MODE on:YES];
    }
    return self;
}

- (instancetype) initWithFileName:(NSString *)fileName
{
    self = [super initWithNibName:@"OARoutePlanningHudViewController"
                           bundle:nil];
    if (self)
    {
        [self commonInit];
        
        _fileName = fileName;
        
        [self setMode:PLAN_ROUTE_MODE on:YES];
    }
    return self;
}

- (instancetype) initWithInitialPoint:(CLLocation *)latLon
{
    self = [super initWithNibName:@"OARoutePlanningHudViewController"
                           bundle:nil];
    if (self)
    {
        [self commonInit];
    
        _initialPoint = latLon;
        [self setMode:PLAN_ROUTE_MODE on:YES];
    }
    return self;
}

- (instancetype) initWithEditingContext:(OAMeasurementEditingContext *)editingCtx followTrackMode:(BOOL)followTrackMode
{
    self = [super initWithNibName:@"OARoutePlanningHudViewController"
                           bundle:nil];
    if (self)
    {
        [self commonInit:editingCtx];
        [self setMode:FOLLOW_TRACK_MODE on:followTrackMode];
    }
    return self;
}

- (void) commonInit
{
    [self commonInit:[[OAMeasurementEditingContext alloc] init]];
}

- (void) commonInit:(OAMeasurementEditingContext *)context
{
    _app = OsmAndApp.instance;
    _settings = [OAAppSettings sharedManager];
    _mapPanel = OARootViewController.instance.mapPanel;
    _layer = _mapPanel.mapViewController.mapLayers.routePlanningLayer;
    _modes = 0x0;
    
    _editingContext = context;
    _editingContext.progressDelegate = self;
    _layer.editingCtx = _editingContext;
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
    
    [self setupModeButton];
    
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
    [self adjustActionButtonsPosition:self.getViewHeight];
    [self adjustNavbarPosition];

    self.tableView.userInteractionEnabled = YES;
    [self.view bringSubviewToFront:self.tableView];
    
    [self addInitialPoint];
    
    OAGpxData *gpxData = _editingContext.gpxData;
    [self initMeasurementMode:gpxData addPoints:YES];
    
    if (gpxData)
    {
        [gpxData.gpxFile initBounds];
        OAGpxBounds bounds = gpxData.rect;
        [self centerMapOnBBox:bounds];
    }
    
    if (_fileName)
        [self addNewGpxData:[self getGpxFile:_fileName]];
//    else if (editingCtx.isApproximationNeeded() && isFollowTrackMode())
//        enterApproximationMode(mapActivity);
}

- (BOOL)supportsFullScreen
{
    return NO;
}

- (BOOL) showStatusBarWhenFullScreen
{
    return NO;
}

- (CGFloat)initialMenuHeight
{
    return _hudMode == EOAHudModeRoutePlanning ? 62. + self.toolBarView.frame.size.height : _infoView.getViewHeight;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)useGestureRecognizer
{
    return NO;
}

- (BOOL) isLeftSidePresentation
{
    if (OAUtilities.isIPad)
        return OAUtilities.isLandscape && _hudMode == EOAHudModeRoutePlanning && !OAUtilities.isWindowed;
    return OAUtilities.isLandscape;
}

- (void) addInitialPoint
{
    if (_initialPoint)
    {
        [_editingContext.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:_layer coordinate:_initialPoint]];
        _initialPoint = nil;
    }
}

- (void) adjustActionButtonsPosition:(CGFloat)height
{
    CGRect buttonsFrame = _actionButtonsContainer.frame;
    if ([self isLeftSidePresentation])
        buttonsFrame.origin = CGPointMake(self.scrollableView.frame.size.width, DeviceScreenHeight - buttonsFrame.size.height - 15. - OAUtilities.getBottomMargin);
    else
        buttonsFrame.origin = CGPointMake(0., DeviceScreenHeight - height - buttonsFrame.size.height - 15.);
    _actionButtonsContainer.frame = buttonsFrame;
}

- (void) changeMapRulerPosition
{
    CGFloat bottomMargin = [self isLeftSidePresentation] ? kDefaultMapRulerMarginBottom : (-self.getViewHeight + OAUtilities.getBottomMargin - 25.);
    CGFloat leftMargin = [self isLeftSidePresentation] ? self.scrollableView.frame.size.width - OAUtilities.getLeftMargin + 16.0 + self.actionButtonsContainer.frame.size.width : kDefaultMapRulerMarginLeft;
    [_mapPanel targetSetMapRulerPosition:bottomMargin left:leftMargin];
}

- (void) changeCenterOffset:(CGFloat)contentHeight
{
    if ([self isLeftSidePresentation])
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
    if ([self isLeftSidePresentation])
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

- (void) adjustNavbarPosition
{
    _navbarLeadingConstraint.constant = [self isLeftSidePresentation] ? self.scrollableView.frame.size.width : 0.;
}

- (void) updateDistancePointsText
{
    if (_layer != nil)
    {
        NSString *distanceStr = [_app getFormattedDistance:_editingContext.getRouteDistance];
        self.titleLabel.text = [NSString stringWithFormat:@"%@, %@ %ld", distanceStr, OALocalizedString(@"points_count"), _editingContext.getPointsCount];
    }
}

- (void)setupModeButton
{
    UIImage *img;
    UIColor *tint;
    if (_editingContext.appMode != OAApplicationMode.DEFAULT)
    {
        img = [_editingContext.appMode.getIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        tint = UIColorFromRGB(_editingContext.appMode.getIconColor);
    }
    else
    {
        img = [[UIImage imageNamed:@"ic_custom_straight_line"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        tint = UIColorFromRGB(color_chart_orange);
    }
    [_modeButton setImage:img forState:UIControlStateNormal];
    [_modeButton setTintColor:tint];
}

- (void) cancelModes
{
    _editingContext.selectedPointPosition = -1;
    _editingContext.originalPointToMove = nil;
    _editingContext.addPointMode = EOAAddPointModeUndefined;
    [_editingContext splitSegments:_editingContext.getBeforePoints.count + _editingContext.getAfterPoints.count];
    if (_hudMode == EOAHudModeMovePoint)
        [_layer exitMovingMode];
    [_layer updateLayer];
    _hudMode = EOAHudModeRoutePlanning;
    
    [self onPointsListChanged];
}

- (OAGPXMutableDocument *) getGpxFile:(NSString *)gpxFileName
{
    OAGPXMutableDocument *gpxFile = nil;
    OASelectedGPXHelper *selectedGpxHelper = OASelectedGPXHelper.instance;
    OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:gpxFileName];
    const auto selectedFileConst = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(selectedGpxHelper.activeGpx[QString::fromNSString(gpxFileName.lastPathComponent)]);
    const auto selectedFile = std::const_pointer_cast<OsmAnd::GpxDocument>(selectedFileConst);
    if (selectedFile != nullptr)
        gpxFile = [[OAGPXMutableDocument alloc] initWithGpxDocument:selectedFile];
    else
        gpxFile = [[OAGPXMutableDocument alloc] initWithGpxFile:[_app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath]];
    
    if (!gpxFile.routes)
        gpxFile.routes = [NSMutableArray new];
    if (!gpxFile.tracks)
        gpxFile.tracks = [NSMutableArray new];
    if (!gpxFile.locationMarks)
        gpxFile.locationMarks = [NSMutableArray new];
    
    return gpxFile;
}

- (void) addNewGpxData:(OAGPXMutableDocument *)gpxFile
{
    OAGpxData *gpxData = [self setupGpxData:gpxFile];
    [self initMeasurementMode:gpxData addPoints:YES];
    if (gpxData)
    {
        OAGpxBounds bounds = gpxData.rect;
        [self centerMapOnBBox:bounds];
    }
}

- (void)centerMapOnBBox:(OAGpxBounds)routeBBox
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL landscape = [self isLeftSidePresentation];
    [mapPanel displayAreaOnMap:routeBBox.topLeft bottomRight:routeBBox.bottomRight zoom:0 bottomInset:!landscape ? self.getViewHeight : 0 leftInset:landscape ? self.tableView.frame.size.width : 0];
}

- (OAGpxData *) setupGpxData:(OAGPXMutableDocument *)gpxFile
{
    OAGpxData *gpxData = nil;
    if (gpxFile != nil)
        gpxData = [[OAGpxData alloc] initWithFile:gpxFile];
    _editingContext.gpxData = gpxData;
    return gpxData;
}

- (void) initMeasurementMode:(OAGpxData *)gpxData addPoints:(BOOL)addPoints
{
    [_editingContext.commandManager setMeasurementLayer:_layer];
//    [self enterMeasurementMode];
    if (gpxData != nil && addPoints)
    {
        if (!self.isUndoMode)
        {
            NSArray<OAGpxRtePt *> *points = gpxData.gpxFile.getRoutePoints;
            if (points.count > 0)
            {
                OAGpxTrkPt *pt = [[OAGpxTrkPt alloc] initWithRtePt:points.lastObject];
                OAApplicationMode *snapToRoadAppMode = [OAApplicationMode valueOfStringKey:pt.getProfileType def:nil];
                if (snapToRoadAppMode)
                    [self setAppMode:snapToRoadAppMode];
            }
        }
        [self collectPoints];
    }
    [self setupModeButton];
    [self setMode:UNDO_MODE on:NO];
}

- (void) setAppMode:(OAApplicationMode *)appMode
{
    _editingContext.appMode = appMode;
    [_editingContext scheduleRouteCalculateIfNotEmpty];
    [self setupModeButton];
}

- (void) collectPoints
{
    if (!self.isUndoMode)
    {
        [_editingContext addPoints];
        [_layer updateLayer];
    }
    [self updateDistancePointsText];
}

- (void)dismiss
{
    [self hide:YES duration:.2 onComplete:^{
        [_mapPanel targetSetMapRulerPosition:kDefaultMapRulerMarginBottom left:kDefaultMapRulerMarginLeft];
        [self restoreMapViewPort];
        [OARootViewController.instance.mapPanel hideScrollableHudViewController];
        _layer.editingCtx = nil;
        [_layer resetLayer];
    }];
}

- (void) handleMapTap:(CLLocationCoordinate2D)coord longPress:(BOOL)longPress
{
    if (!_editingContext.isInAddPointMode && _editingContext.selectedPointPosition == -1)
        [self selectPoint:coord longPress:longPress];
}

- (double) getLowestDistance:(OAMapRendererView *)mapView
{
    CGPoint first = CGPointZero;
    // 44 is the height of a point in px
    CGPoint second = CGPointMake(0., 44.);
    
    OsmAnd::PointI firstPoint;
    OsmAnd::PointI secondPoint;
    
    [mapView convert:first toLocation:&firstPoint];
    [mapView convert:second toLocation:&secondPoint];
    
    OsmAnd::LatLon firstLatLon = OsmAnd::Utilities::convert31ToLatLon(firstPoint);
    OsmAnd::LatLon secondLatLon = OsmAnd::Utilities::convert31ToLatLon(secondPoint);
    
    return getDistance(firstLatLon.latitude, firstLatLon.longitude, secondLatLon.latitude, secondLatLon.longitude);
}

- (void) selectPoint:(CLLocationCoordinate2D)location longPress:(BOOL)longPress
{
    OAMapRendererView *mapView = OARootViewController.instance.mapPanel.mapViewController.mapView;
    
    double lowestDistance = [self getLowestDistance:mapView];
    for (NSInteger i = 0; i < _editingContext.getPointsCount; i++)
    {
        OAGpxTrkPt *pt = _editingContext.getPoints[i];
        const auto latLon = OsmAnd::LatLon(pt.getLatitude, pt.getLongitude);
        const auto point = OsmAnd::Utilities::convertLatLonTo31(latLon);
        
        if (mapView.getVisibleBBox31.contains(point))
        {
            double distToPoint = getDistance(location.latitude, location.longitude, latLon.latitude, latLon.longitude);
            if (distToPoint < lowestDistance)
            {
                lowestDistance = distToPoint;
                _editingContext.selectedPointPosition = i;
            }
        }
    }
    if (_editingContext.selectedPointPosition != -1)
    {
        if (longPress)
            [self onMovePoint:_editingContext.selectedPointPosition];
        else
            [self openSelectedPointMenu];
    }
    else if (!longPress)
    {
        _layer.pressPointLocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
        [_editingContext.commandManager execute:[[OAAddPointCommand alloc] initWithLayer:_layer center:NO]];
        [self onPointsListChanged];
    }
}

- (CLLocationCoordinate2D) getTouchPointCoord:(CGPoint)touchPoint
{
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    touchPoint.x *= mapViewController.mapView.contentScaleFactor;
    touchPoint.y *= mapViewController.mapView.contentScaleFactor;
    OsmAnd::PointI touchLocation;
    [mapViewController.mapView convert:touchPoint toLocation:&touchLocation];
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

- (void) startTrackNavigation
{
    if (_editingContext.hasRoute || _editingContext.hasChanges)
    {
        NSString *trackName = [self getSuggestedFileName];
        OAGPXDocument *gpx = [_editingContext exportGpx:trackName];
        if (gpx != nil)
        {
            OAApplicationMode *appMode = _editingContext.appMode;
            [self onCloseButtonPressed];
            [self runNavigation:gpx appMode:appMode];
        }
        else
        {
            NSLog(@"An error occured while saving route planning track for navigation");
        }
    }
    else
    {
        NSLog(@"An error occured while saving route planning track for navigation: no route to save");
    }
}

- (IBAction)closePressed:(id)sender
{
    if (_editingContext.hasChanges)
    {
        OAExitRoutePlanningBottomSheetViewController *bottomSheet = [[OAExitRoutePlanningBottomSheetViewController alloc] init];
        bottomSheet.delegate = self;
        [bottomSheet presentInViewController:OARootViewController.instance.mapPanel.mapViewController];
    }
    else
    {
        [self dismiss];
    }
}

- (IBAction)donePressed:(id)sender
{
    if ([self isFollowTrackMode])
        [self startTrackNavigation];
    else
        [self saveChanges:SHOW_SNACK_BAR_AND_CLOSE showDialog:NO];
    [self dismiss];
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
    BOOL trackSnappedToRoad = !_editingContext.isApproximationNeeded;
    BOOL addNewSegmentAllowed = _editingContext.isAddNewSegmentAllowed;
    OAPlanningOptionsBottomSheetViewController *bottomSheet = [[OAPlanningOptionsBottomSheetViewController alloc] initWithRouteAppModeKey:_editingContext.appMode.stringKey trackSnappedToRoad:trackSnappedToRoad addNewSegmentAllowed:addNewSegmentAllowed];
    bottomSheet.delegate = self;
    [bottomSheet presentInViewController:self];
}

- (IBAction)onUndoButtonPressed:(id)sender
{
    [_editingContext.commandManager undo];
    [self onPointsListChanged];
    [self setupModeButton];
}

- (IBAction)onRedoButtonPressed:(id)sender
{
    [_editingContext.commandManager redo];
    [self onPointsListChanged];
    [self setupModeButton];
}

- (IBAction)onAddPointPressed:(id)sender
{
    [self addCenterPoint];
}

- (void)showSegmentRouteOptions
{
    OASegmentOptionsBottomSheetViewController *bottomSheet = [[OASegmentOptionsBottomSheetViewController alloc] initWithType:EOADialogTypeWholeRouteCalculation dialogMode:EOARouteBetweenPointsDialogModeAll appMode:_editingContext.appMode];
    bottomSheet.delegate = self;
    [bottomSheet presentInViewController:self];
}

- (IBAction)modeButtonPressed:(id)sender
{
    [self showSegmentRouteOptions];
}

- (void) setMode:(int)mode on:(BOOL)on
{
    int modes = _modes;
    if (on)
        modes |= mode;
    else
        modes &= ~mode;
    _modes = modes;
}

- (BOOL)isPlanRouteMode
{
    return (_modes & PLAN_ROUTE_MODE) == PLAN_ROUTE_MODE;
}

- (BOOL) isDirectionMode
{
    return (_modes & DIRECTION_MODE) == DIRECTION_MODE;
}

- (BOOL) isFollowTrackMode
{
    return (_modes & FOLLOW_TRACK_MODE) == FOLLOW_TRACK_MODE;
}

- (BOOL) isUndoMode
{
    return (_modes & UNDO_MODE) == UNDO_MODE;
}

- (BOOL) isInEditMode
{
    return ![self isPlanRouteMode] && !_editingContext.isNewData && ![self isDirectionMode] && ![self isFollowTrackMode];
}

- (NSString *) getSuggestedFileName
{
    OAGpxData *gpxData = _editingContext.gpxData;
    NSString *displayedName = nil;
    if (gpxData != nil) {
        OAGPXDocument *gpxFile = gpxData.gpxFile;
        if (gpxFile.path.length > 0)
            displayedName = gpxFile.path.lastPathComponent.stringByDeletingPathExtension;
        else if (gpxFile.tracks.count > 0)
            displayedName = gpxFile.tracks.firstObject.name;
    }
    if (gpxData == nil || displayedName == nil)
    {
        NSDateFormatter *objDateFormatter = [[NSDateFormatter alloc] init];
        [objDateFormatter setDateFormat:@"EEE dd MMM yyyy"];
        NSString *suggestedName = [objDateFormatter stringFromDate:[NSDate date]];
        displayedName = [self createUniqueFileName:suggestedName];
    }
    else
    {
        displayedName = gpxData.gpxFile.path.lastPathComponent.stringByDeletingPathExtension;
    }
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
            path = [[_app.gpxPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"gpx"];
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
        if ([_editingContext isNewData])
        {
            if (showDialog)
                [self openSaveAsNewTrackMenu];
            else
                [self saveNewGpx:nil fileName:[self getSuggestedFileName] showOnMap:YES simplifiedTrack:NO finalSaveAction:finalSaveAction];
        }
        else
        {
            [self addToGpx:finalSaveAction];
        }
    }
    else
    {
        [self showNoPointsAlert];
    }
}

- (void) addToGpx:(EOAFinalSaveAction)finalSaveAction
{
    OAGpxData *gpxData = _editingContext.gpxData;
    OAGPXDocument *gpx = gpxData != nil ? gpxData.gpxFile : nil;
    if (gpx != nil)
    {
        OASelectedGPXHelper *helper = OASelectedGPXHelper.instance;
        BOOL showOnMap = helper.activeGpx.find(QString::fromNSString(gpx.path)) != helper.activeGpx.end();
        [self saveExistingGpx:gpx showOnMap:showOnMap simplified:NO addToTrack:NO finalSaveAction:finalSaveAction];
    }
}

- (void) saveExistingGpx:(OAGPXDocument *)gpx showOnMap:(BOOL)showOnMap
                                 simplified:(BOOL)simplified addToTrack:(BOOL)addToTrack finalSaveAction:(EOAFinalSaveAction)finalSaveAction
{
    [self saveGpx:gpx.path gpxFile:gpx simplified:simplified addToTrack:addToTrack finalSaveAction:finalSaveAction showOnMap:showOnMap];
}

- (void) saveNewGpx:(NSString *)folderName fileName:(NSString *)fileName showOnMap:(BOOL)showOnMap
    simplifiedTrack:(BOOL)simplifiedTrack finalSaveAction:(EOAFinalSaveAction)finalSaveAction
{
    NSString *gpxPath = _app.gpxPath;
    if (folderName != nil && ![gpxPath.lastPathComponent isEqualToString:folderName])
        gpxPath = [gpxPath stringByAppendingPathComponent:folderName];
    fileName = [fileName stringByAppendingPathExtension:@"gpx"];
    [self saveNewGpx:gpxPath fileName:fileName showOnMap:showOnMap simplified:simplifiedTrack finalSaveAction:finalSaveAction];
}

- (void) saveNewGpx:(NSString *)dir fileName:(NSString *)fileName showOnMap:(BOOL)showOnMap simplified:(BOOL)simplified finalSaveAction:(EOAFinalSaveAction)finalSaveAction
{
    [self saveGpx:[dir stringByAppendingPathComponent:fileName] gpxFile:nil simplified:simplified addToTrack:NO finalSaveAction:finalSaveAction showOnMap:showOnMap];
}

- (void) saveGpx:(NSString *)outFile gpxFile:(OAGPXDocument *)gpxFile simplified:(BOOL)simplified addToTrack:(BOOL)addToTrack finalSaveAction:(EOAFinalSaveAction)finalSaveAction showOnMap:(BOOL)showOnMap
{
    OASaveGpxRouteAsyncTask *task = [[OASaveGpxRouteAsyncTask alloc] initWithHudController:self outFile:outFile gpxFile:gpxFile simplified:simplified addToTrack:addToTrack showOnMap:showOnMap];
    [task execute:^(OAGPXDocument * gpx, NSString * outFile) {
        [self onGpxSaved:gpx outFile:outFile finalSaveAction:finalSaveAction showOnMap:showOnMap];
    }];
}

- (void) onGpxSaved:(OAGPXDocument *)savedGpxFile outFile:(NSString *)outFile finalSaveAction:(EOAFinalSaveAction)finalSaveAction showOnMap:(BOOL)showOnMap
{
    if (_editingContext.isNewData && savedGpxFile != nil)
    {
        OAGpxData *gpxData = [[OAGpxData alloc] initWithFile:(OAGPXMutableDocument *)savedGpxFile];
        _editingContext.gpxData = gpxData;
    }
    if ([self isInEditMode])
    {
        [_editingContext setChangesSaved];
        [self dismiss];
    }
    else
    {
        switch (finalSaveAction)
        {
            case SHOW_SNACK_BAR_AND_CLOSE:
            {
                //TODO: implement snackbar in the future
//                final WeakReference<MapActivity> mapActivityRef = new WeakReference<>(mapActivity);
//                Snackbar snackbar = Snackbar.make(mapActivity.getLayout(),
//                                                  MessageFormat.format(getString(R.string.gpx_saved_sucessfully), outFile.getName()),
//                                                  Snackbar.LENGTH_LONG)
//                .setAction(R.string.shared_string_undo, new OnClickListener() {
//                    @Override
//                    public void onClick(View view) {
//                        MapActivity mapActivity = mapActivityRef.get();
//                        if (mapActivity != null) {
//                            OsmandApplication app = mapActivity.getMyApplication();
//                            FileUtils.removeGpxFile(app, outFile);
//                            if (backupFile != null) {
//                                FileUtils.renameGpxFile(app, backupFile, outFile);
//                                GPXFile gpx = GPXUtilities.loadGPXFile(outFile);
//                                setupGpxData(gpx);
//                                if (showOnMap) {
//                                    showGpxOnMap(app, gpx, false);
//                                }
//                            } else {
//                                setupGpxData(null);
//                            }
//                            setMode(UNDO_MODE, true);
//                            MeasurementToolFragment.showInstance(mapActivity.getSupportFragmentManager(),
//                                                                 editingCtx, modes);
//                        }
//                    }
//                })
//                .addCallback(new Snackbar.Callback() {
//                    @Override
//                    public void onDismissed(Snackbar transientBottomBar, int event) {
//                        if (event != DISMISS_EVENT_ACTION) {
//                            editingCtx.setChangesSaved();
//                        }
//                        super.onDismissed(transientBottomBar, event);
//                    }
//                });
//                snackbar.getView().<TextView>findViewById(com.google.android.material.R.id.snackbar_action)
//                .setAllCaps(false);
//                UiUtilities.setupSnackbar(snackbar, nightMode);
//                snackbar.show();
                [self dismiss];
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:OALocalizedString(@"gpx_saved_successfully"), outFile.lastPathComponent.stringByDeletingPathExtension] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
                [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
                break;
            }
            case SHOW_IS_SAVED_FRAGMENT:
            {
                [_editingContext setChangesSaved];
                [self hide:NO duration:.2 onComplete:^{
                    [_mapPanel targetSetMapRulerPosition:kDefaultMapRulerMarginBottom left:kDefaultMapRulerMarginLeft];
                    [self restoreMapViewPort];
                    [OARootViewController.instance.mapPanel hideScrollableHudViewController];
                    _layer.editingCtx = nil;
                    [_layer resetLayer];
                    
                    OASaveTrackBottomSheetViewController *bottomSheet = [[OASaveTrackBottomSheetViewController alloc] initWithFileName:outFile];
                    [bottomSheet presentInViewController:OARootViewController.instance];
                }];
                break;
            }
            case SHOW_TOAST:
            {
                [_editingContext setChangesSaved];
                if (savedGpxFile != nil /*&& !savedGpxFile.showCurrentTrack*/)
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:OALocalizedString(@"gpx_saved_successfully"), outFile.lastPathComponent.stringByDeletingPathExtension] preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
                    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
                }
            }
        }
    }
    OASelectedGPXHelper *helper = OASelectedGPXHelper.instance;
    NSString *gpxFilePath = [OAUtilities getGpxShortPath:outFile];
    if ([_settings.mapSettingVisibleGpx containsObject:gpxFilePath])
    {
        // Refresh track if visible
        [_settings hideGpx:@[gpxFilePath] update:YES];
        helper.activeGpx.remove(QString::fromNSString(outFile));
        [helper buildGpxList];
    }
    if (showOnMap)
    {
        [_settings showGpx:@[gpxFilePath]];
    }
}

- (void)showNoPointsAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"none_point_error") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
}

- (void) openSaveAsNewTrackMenu
{
    if (_editingContext.getPointsCount > 0)
    {
        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc] initWithParams:[self getSuggestedFileName] showOnMap:YES simplifiedTrack:YES];
        saveTrackViewController.delegate = self;
        [self presentViewController:saveTrackViewController animated:YES completion:nil];
    }
    else
    {
        [self showNoPointsAlert];
    }
}

- (void) showAddToTrackDialog
{
    OAOpenAddTrackViewController *saveTrackViewController = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOAAddToATrack];
    saveTrackViewController.delegate = self;
    [self presentViewController:saveTrackViewController animated:YES completion:nil];
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeCenterOffset:height];
    [_mapPanel targetSetBottomControlsVisible:YES menuHeight:[self isLeftSidePresentation] ? 0. : (height - ([OAUtilities isIPad] ? 0. : 30.)) animated:YES];
    [self adjustActionButtonsPosition:height];
    [self changeMapRulerPosition];
    [self adjustMapViewPort];
    [self adjustNavbarPosition];
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

- (void)openSelectedPointMenu
{
    NSInteger selectedPos = _editingContext.selectedPointPosition;
    OAPointOptionsBottomSheetViewController *bottomSheet = [[OAPointOptionsBottomSheetViewController alloc] initWithPoint:_editingContext.getPoints[selectedPos] index:selectedPos editingContext:_editingContext];
    bottomSheet.delegate = self;
    [bottomSheet presentInViewController:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _editingContext.selectedPointPosition = indexPath.row;
    [self openSelectedPointMenu];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAMeasurementLayerDelegate

- (void)onMeasure:(double)distance bearing:(double)bearing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.descriptionLabel.text = [NSString stringWithFormat:@"%@ • %@", [_app getFormattedDistance:distance], [OsmAndApp.instance getFormattedAzimuth:bearing]];
    });
}

- (void)onTouch:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress
{
    [self handleMapTap:coordinate longPress:longPress];
}

#pragma mark - OAPointOptionsBottmSheetDelegate

- (void)showMovingInfoView
{
    _infoView = [[OAInfoBottomView alloc] initWithType:EOABottomInfoViewTypeMove];
    _infoView.frame = self.scrollableView.bounds;
    _infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _infoView.leftIconView.image = [UIImage imageNamed:@"ic_custom_change_object_position"];
    _infoView.titleView.text = OALocalizedString(@"move_point");
    _infoView.headerViewText = OALocalizedString(@"move_point_descr");
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
    OAGpxTrkPt *pt = _editingContext.getPoints[pointPosition];
    _editingContext.originalPointToMove = pt;
    [_layer enterMovingPointMode];
    [self onPointsListChanged];
}

- (void) onClearPoints:(EOAClearPointsMode)mode
{
    [_editingContext.commandManager execute:[[OAClearPointsCommand alloc] initWithMeasurementLayer:_layer mode:mode]];
    [self onPointsListChanged];
    [self goMinimized];
    _editingContext.selectedPointPosition = -1;
    [_editingContext splitSegments:_editingContext.getBeforePoints.count + _editingContext.getAfterPoints.count];
//    updateUndoRedoButton(false, redoBtn);
//    updateUndoRedoButton(true, undoBtn);
    [self updateDistancePointsText];
}

- (void)onAddPoints:(EOAAddPointMode)type
{
    BOOL addBefore = type == EOAAddPointModeBefore;
    EOABottomInfoViewType viewType = type == EOAAddPointModeBefore ? EOABottomInfoViewTypeAddBefore : EOABottomInfoViewTypeAddAfter;
    _infoView = [[OAInfoBottomView alloc] initWithType:viewType];
    _infoView.frame = self.scrollableView.bounds;
    _infoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _infoView.leftIconView.image = addBefore ? [UIImage imageNamed:@"ic_custom_add_point_before"] : [UIImage imageNamed:@"ic_custom_add_point_after"];
    _infoView.titleView.text = addBefore ? OALocalizedString(@"add_before") : OALocalizedString(@"add_after");
    _infoView.headerViewText = OALocalizedString(@"move_point_descr");
    [_infoView.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_infoView.rightButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
    _infoView.layer.cornerRadius = 9.;
    _infoView.clipsToBounds = NO;
    _infoView.layer.masksToBounds = YES;
    
    [_layer moveMapToPoint:_editingContext.selectedPointPosition];
    _editingContext.addPointMode = type;
    [_editingContext splitSegments:_editingContext.selectedPointPosition + (type == EOAAddPointModeAfter ? 1 : 0)];
    
    [_layer updateLayer];
    
    [self onPointsListChanged];
    
    _infoView.delegate = self;
    [self.scrollableView addSubview:_infoView];
    _hudMode = EOAHudModeAddPoints;
    [self goMinimized];
}

- (void) onDeletePoint
{
    [_editingContext.commandManager execute:[[OARemovePointCommand alloc] initWithLayer:_layer position:_editingContext.selectedPointPosition]];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [self updateDistancePointsText];
    _editingContext.selectedPointPosition = -1;
}

- (void)onClearSelection
{
    _editingContext.selectedPointPosition = -1;
}

- (void)onCloseMenu
{
    
}

#pragma mark - OAInfoBottomViewDelegate

- (void)onLeftButtonPressed
{
    [self onCloseButtonPressed];
}

- (void)onRightButtonPressed
{
    OAGpxTrkPt *newPoint = [_layer getMovedPointToApply];
    if (_hudMode == EOAHudModeMovePoint)
    {
        [_editingContext.commandManager execute:[[OAMovePointCommand alloc] initWithLayer:_layer
                                                                                 oldPoint:_editingContext.originalPointToMove
                                                                                 newPoint:newPoint
                                                                                 position:_editingContext.selectedPointPosition]];
        [_editingContext addPoint:newPoint];
        [self exitMovePointMode:NO];
    }
    else if (_hudMode == EOAHudModeAddPoints)
    {
        [self onAddOneMorePointPressed:_editingContext.addPointMode];
        [self exitAddPointMode];
    }
    [self hideInfoView];
}

- (void)onCloseButtonPressed
{
    if (_hudMode == EOAHudModeMovePoint)
    {
        [self exitMovePointMode:YES];
    }
    else if (_hudMode == EOAHudModeAddPoints)
    {
        [self exitAddPointMode];
    }
    [self hideInfoView];
}

- (void)hideInfoView
{
    [UIView animateWithDuration:.2 animations:^{
        _infoView.alpha = 0.;
        [self goMinimized];
        [self onPointsListChanged];
    } completion:^(BOOL finished) {
        [_infoView removeFromSuperview];
        _infoView = nil;
    }];
}

- (void) exitMovePointMode:(BOOL)cancelled
{
    if (cancelled)
    {
        OAGpxTrkPt *pt = _editingContext.originalPointToMove;
        [_editingContext addPoint:pt];
    }
    _editingContext.selectedPointPosition = -1;
    _editingContext.originalPointToMove = nil;
    [_editingContext splitSegments:_editingContext.getBeforePoints.count + _editingContext.getAfterPoints.count];
    [_layer exitMovingMode];
    [_layer updateLayer];
    _hudMode = EOAHudModeRoutePlanning;
    [self onPointsListChanged];
}

- (void)exitAddPointMode
{
    _editingContext.selectedPointPosition = -1;
    _editingContext.originalPointToMove = nil;
    _editingContext.addPointMode = EOAAddPointModeUndefined;
    [_editingContext splitSegments:_editingContext.getBeforePoints.count + _editingContext.getAfterPoints.count];
    [_layer updateLayer];
    _hudMode = EOAHudModeRoutePlanning;
    [self onPointsListChanged];
}

- (void) onAddOneMorePointPressed:(EOAAddPointMode)mode
{
    NSInteger selectedPoint = _editingContext.selectedPointPosition;
    NSInteger pointsCount = _editingContext.getPointsCount;
    if ([self addCenterPoint])
    {
        if (selectedPoint == pointsCount)
            [_editingContext splitSegments:_editingContext.getPointsCount - 1];
        else
            _editingContext.selectedPointPosition = selectedPoint + 1;
        
        [self onPointsListChanged];
    }
}

- (void)onChangeRouteTypeBefore
{
    OASegmentOptionsBottomSheetViewController *bottomSheet = [[OASegmentOptionsBottomSheetViewController alloc] initWithType:EOADialogTypePrevRouteCalculation dialogMode:EOARouteBetweenPointsDialogModeSingle appMode:_editingContext.getBeforeSelectedPointAppMode];
    bottomSheet.delegate = self;
    [bottomSheet presentInViewController:self];
}

- (void)onChangeRouteTypeAfter
{
    OASegmentOptionsBottomSheetViewController *bottomSheet = [[OASegmentOptionsBottomSheetViewController alloc] initWithType:EOADialogTypeNextRouteCalculation dialogMode:EOARouteBetweenPointsDialogModeSingle appMode:_editingContext.getSelectedPointAppMode];
    bottomSheet.delegate = self;
    [bottomSheet presentInViewController:self];
}

- (void) onSplitPointsAfter
{
    [_editingContext.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:_layer after:YES]];
    [_editingContext setSelectedPointPosition:-1];
    //updateUndoRedoButton(false, redoBtn);
    //updateUndoRedoButton(true, undoBtn);
    [self updateDistancePointsText];
}

- (void) onSplitPointsBefore
{
    [_editingContext.commandManager execute:[[OASplitPointsCommand alloc] initWithLayer:_layer after:NO]];
    [_editingContext setSelectedPointPosition:-1];
    //updateUndoRedoButton(false, redoBtn);
    //updateUndoRedoButton(true, undoBtn);
    [self updateDistancePointsText];
}

- (void) onJoinPoints
{
    [_editingContext.commandManager execute:[[OAJoinPointsCommand alloc] initWithLayer:_layer]];
    [_editingContext setSelectedPointPosition:-1];
    //updateUndoRedoButton(false, redoBtn);
    //updateUndoRedoButton(true, undoBtn);
    [self updateDistancePointsText];
}

#pragma mark - OASegmentOptionsDelegate

- (void)onApplicationModeChanged:(OAApplicationMode *)mode dialogType:(EOARouteBetweenPointsDialogType)dialogType dialogMode:(EOARouteBetweenPointsDialogMode)dialogMode
{
    if (_layer != nil) {
        EOAChangeRouteType changeRouteType = EOAChangeRouteNextSegment;
        switch (dialogType) {
            case EOADialogTypeWholeRouteCalculation:
            {
                changeRouteType = dialogMode == EOARouteBetweenPointsDialogModeSingle
                ? EOAChangeRouteLastSegment : EOAChangeRouteWhole;
                break;
            }
            case EOADialogTypeNextRouteCalculation:
            {
                changeRouteType = dialogMode == EOARouteBetweenPointsDialogModeSingle
                ? EOAChangeRouteNextSegment : EOAChangeRouteAllNextSegments;
                break;
            }
            case EOADialogTypePrevRouteCalculation:
            {
                changeRouteType = dialogMode == EOARouteBetweenPointsDialogModeSingle
                ? EOAChangeRoutePrevSegment : EOAChangeRouteAllPrevSegments;
                break;
            }
        }
        [_editingContext.commandManager execute:[[OAChangeRouteModeCommand alloc] initWithLayer:_layer appMode:mode changeRouteType:changeRouteType pointIndex:_editingContext.selectedPointPosition]];
//        updateUndoRedoButton(false, redoBtn);
//        updateUndoRedoButton(true, undoBtn);
//        disable(upDownBtn);
//        updateSnapToRoadControls();
        [self updateDistancePointsText];
        [self setupModeButton];
    }
}

#pragma mark - OASnapToRoadProgressDelegate

- (void)hideProgressBar
{
    _progressView.hidden = YES;
}

- (void)refresh
{
    [_layer updateLayer];
    [self updateDistancePointsText];
}

- (void)showProgressBar
{
    _progressView.hidden = NO;
}

- (void)updateProgress:(int)progress
{
    [_progressView setProgress:progress / 100.];
}

#pragma mark - OAPlanningOptionsDelegate

- (void) snapToRoadOptionSelected
{
    [self showSegmentRouteOptions];
}

- (void) addNewSegmentSelected
{
    [self onSplitPointsAfter];
}

- (void) saveChangesSelected
{
//    if (self.isFollowTrackMode)
//        [self startTrackNavigation];
//    else
        [self saveChanges:SHOW_TOAST showDialog:YES];
}

- (void) saveAsNewTrackSelected
{
    [self openSaveAsNewTrackMenu];
}

- (void) addToTrackSelected
{
    if (_editingContext.getPointsCount > 0)
        [self showAddToTrackDialog];
//    else
//        NSLog(@"No points to add");
//        Toast.makeText(mapActivity, getString(R.string.none_point_error), Toast.LENGTH_SHORT).show();
}

- (void) directionsSelected
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OATargetPointsHelper *targetPointsHelper = OATargetPointsHelper.sharedInstance;
    OAApplicationMode *appMode = _editingContext.appMode;
    if (appMode == OAApplicationMode.DEFAULT)
        appMode = nil;
    
    NSArray<OAGpxTrkPt *> *points = _editingContext.getPoints;
    if (points.count > 0)
    {
        if (points.count == 1)
        {
            [targetPointsHelper clearAllPoints:NO];
            [targetPointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:points.firstObject.getLatitude longitude:points.firstObject.getLongitude] updateRoute:NO intermediate:-1];
            
            [self onCloseButtonPressed];
            [mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
        }
        else
        {
            NSString *trackName = [self getSuggestedFileName];
            if (_editingContext.hasRoute)
            {
                OAGPXDocument *gpx = [_editingContext exportGpx:trackName];
                if (gpx != nil)
                {
                    [self onCloseButtonPressed];
                    [self runNavigation:gpx appMode:appMode];
                }
//                else
//                {
//                    Toast.makeText(mapActivity, getString(R.string.error_occurred_saving_gpx), Toast.LENGTH_SHORT).show();
//                }
            }
            // TODO: add approximation
//            else
//            {
//                if (editingCtx.isApproximationNeeded()) {
//                    setMode(DIRECTION_MODE, true);
//                    enterApproximationMode(mapActivity);
//                } else {
//                    GPXFile gpx = new GPXFile(Version.getFullVersion(requireMyApplication()));
//                    gpx.addRoutePoints(points, true);
//                    dismiss(mapActivity);
//                    targetPointsHelper.clearAllPoints(false);
//                    mapActions.enterRoutePlanningModeGivenGpx(gpx, appMode, null, null, true, true, MenuState.HEADER_ONLY);
//                }
//            }
        }
    }
    else
    {
        // TODO: notify about the error
//        Toast.makeText(mapActivity, getString(R.string.none_point_error), Toast.LENGTH_SHORT).show();
    }
}

- (void) runNavigation:(OAGPXDocument *)gpx appMode:(OAApplicationMode *)appMode
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OARoutingHelper *routingHelper = OARoutingHelper.sharedInstance;
    OAGPX *track = [OAGPXDatabase.sharedDb getGPXItem:gpx.path];
    if (routingHelper.isFollowingMode)
    {
        if ([self isFollowTrackMode])
        {
            [mapPanel.mapActions setGPXRouteParamsWithDocument:gpx path:gpx.path];
            [OATargetPointsHelper.sharedInstance updateRouteAndRefresh:YES];
            [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
        }
        else
        {
            [mapPanel.mapActions stopNavigationWithoutConfirm];
//            [mapPanel.mapActions enterRoutePlanningModeGivenGpx:track from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
            [mapPanel.mapActions enterRoutePlanningModeGivenGpx:gpx path:track.gpxFilePath from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
        }
    }
    else
    {
        [mapPanel.mapActions stopNavigationWithoutConfirm];
        [mapPanel.mapActions enterRoutePlanningModeGivenGpx:gpx path:track.gpxFilePath from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
//        [mapPanel.mapActions enterRoutePlanningModeGivenGpx:track from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
    }
}

- (void) reverseRouteSelected
{
    NSArray<OAGpxTrkPt *> *points = _editingContext.getPoints;
    if (points.count > 1)
    {
        [_editingContext.commandManager execute:[[OAReversePointsCommand alloc] initWithLayer:_layer]];
        [self goMinimized];
//        updateUndoRedoButton(false, redoBtn);
//        updateUndoRedoButton(true, undoBtn);
        [self.tableView reloadData];
        [self updateDistancePointsText];
    }
    else
    {
        NSLog(@"Can't reverse one point");
    }
}

- (void) clearAllSelected
{
    [_editingContext.commandManager execute:[[OAClearPointsCommand alloc] initWithMeasurementLayer:_layer mode:EOAClearPointsModeAll]];
    [_editingContext cancelSnapToRoad];
    [self goMinimized];
//    updateUndoRedoButton(false, redoBtn);
    [self onPointsListChanged];
}

#pragma mark - OAOpenAddTrackDelegate

- (void)closeBottomSheet
{
}

- (void)onFileSelected:(NSString *)gpxFileName
{
    OAGPXMutableDocument *gpxFile;
    if (!gpxFileName)
        gpxFile = OASavingTrackHelper.sharedInstance.currentTrack;
    else
        gpxFile = [self getGpxFile:gpxFileName];
    OASelectedGPXHelper *selectedGpxHelper = OASelectedGPXHelper.instance;
    BOOL showOnMap = selectedGpxHelper.activeGpx.find(QString::fromNSString(gpxFileName.lastPathComponent)) != selectedGpxHelper.activeGpx.end();
    [self saveExistingGpx:gpxFile showOnMap:showOnMap simplified:NO addToTrack:YES finalSaveAction:SHOW_IS_SAVED_FRAGMENT];
}

#pragma mark - OASaveTrackViewControllerDelegate

- (void)onSaveAsNewTrack:(NSString *)fileName showOnMap:(BOOL)showOnMap simplifiedTrack:(BOOL)simplifiedTrack
{
    [self saveNewGpx:@"" fileName:fileName showOnMap:showOnMap simplifiedTrack:simplifiedTrack finalSaveAction:SHOW_IS_SAVED_FRAGMENT];
}

#pragma mark - OAExitRoutePlanningDelegate

- (void)onExitRoutePlanningPressed
{
    [self dismiss];
}

- (void)onSaveResultPressed
{
    [self openSaveAsNewTrackMenu];
}

@end
