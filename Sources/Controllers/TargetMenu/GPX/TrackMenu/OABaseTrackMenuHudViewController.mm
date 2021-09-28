//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@interface OABaseTrackMenuHudViewController()

@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) OAMapViewController *mapViewController;

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OASavingTrackHelper *savingHelper;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) OAGPXDocument *doc;
@property (nonatomic) BOOL isCurrentTrack;
@property (nonatomic) BOOL isShown;

@property (nonatomic) CGFloat cachedYViewPort;
@property (nonatomic) NSArray<NSDictionary *> *data;

@end

@implementation OABaseTrackMenuHudViewController
{

}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super init]; //override initWithNibName
    if (self)
    {
        self.gpx = gpx;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.app = [OsmAndApp instance];
    self.settings = [OAAppSettings sharedManager];
    self.savingHelper = [OASavingTrackHelper sharedInstance];
    self.mapPanelViewController = [OARootViewController instance].mapPanel;
    self.mapViewController = self.mapPanelViewController.mapViewController;

    self.isCurrentTrack = !self.gpx || self.gpx.gpxFilePath.length == 0 || self.gpx.gpxFileName.length == 0;
    if (self.isCurrentTrack)
    {
        if (!self.gpx)
            self.gpx = [self.savingHelper getCurrentGPX];

        self.gpx.gpxTitle = OALocalizedString(@"track_recording_name");
    }
    self.doc = self.isCurrentTrack ? (OAGPXDocument *) self.savingHelper.currentTrack
            : [[OAGPXDocument alloc] initWithGpxFile:[self.app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath]];

    self.isShown = [self.settings.mapSettingVisibleGpx.get containsObject:self.gpx.gpxFilePath];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupView];
    if (![self isLandscape])
        [self goExpanded];
    else
        [self goFullScreen];

    [self.mapPanelViewController displayGpxOnMap:self.gpx];
    [self.mapPanelViewController setTopControlsVisible:NO
                              customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                      ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    self.cachedYViewPort = self.mapViewController.mapView.viewportYScale;
    [self adjustMapViewPort];
}

- (void)firstShowing
{
    [self show:YES
         state:[self isLandscape] ? EOADraggableMenuStateFullScreen : EOADraggableMenuStateExpanded
    onComplete:^{
        [self.mapPanelViewController targetSetBottomControlsVisible:YES
                                                     menuHeight:[self isLandscape] ? 0
                                                             : [self getViewHeight] - [OAUtilities getBottomMargin]
                                                       animated:YES];
        [self changeMapRulerPosition];
        [self.mapPanelViewController.hudViewController updateMapRulerData];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [self.mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [self restoreMapViewPort];
        [self.mapPanelViewController hideScrollableHudViewController];
        if (onComplete)
            onComplete();
    }];
}

- (void)dismiss:(void (^)(void))onComplete
{
    [self hide:YES duration:.2 onComplete:onComplete];
}

- (void)setupView
{
    [self.backButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_back"] forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];

    [self generateData];
    [self setupHeaderView];
//    [self.view bringSubviewToFront:self.tableView];
}

- (void)setupHeaderView
{
    //override
}

- (void)generateData
{
    //override
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)showStatusBarWhenFullScreen
{
    return YES;
}

- (void)doAdditionalLayout
{
    self.backButtonLeadingConstraint.constant = [self isLandscape] ? self.tableView.frame.size.width : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (void)adjustMapViewPort
{
    self.mapViewController.mapView.viewportXScale = [self isLandscape] ? VIEWPORT_SHIFTED_SCALE : VIEWPORT_NON_SHIFTED_SCALE;
    self.mapViewController.mapView.viewportYScale = [self getViewHeight] / DeviceScreenHeight;
}

- (void)restoreMapViewPort
{
    OAMapRendererView *mapView = self.mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != self.cachedYViewPort)
        mapView.viewportYScale = self.cachedYViewPort;
}

- (void)changeMapRulerPosition
{
    CGFloat bottomMargin = [self isLandscape] ? 0 : (-[self getViewHeight] + [OAUtilities getBottomMargin] - 20.);
    [self.mapPanelViewController targetSetMapRulerPosition:bottomMargin
                                                  left:([self isLandscape] ? self.tableView.frame.size.width
                                                          : [OAUtilities getLeftMargin] + 20.)];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return self.data[indexPath.section][@"cells"][indexPath.row];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self dismiss:nil];
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    [self.mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0
                                                         : height - [OAUtilities getBottomMargin]
                                                   animated:YES];
    [self changeMapRulerPosition];
    [self adjustMapViewPort];
}

@end
