//
//  OAAddWaypointViewController.mm
//  OsmAnd
//
//  Created by Skalii on 12.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAAddWaypointViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OATrackMenuHudViewController.h"
#import "OAMapRendererView.h"
#import "OAContextMenuLayer.h"
#import "OAMapLayers.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAGpxWptItem.h"
#import "OANativeUtilities.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAPointDescription.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

@interface OAAddWaypointViewController () <OAChangePositionModeDelegate>

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *coordinatesView;

@property (weak, nonatomic) IBOutlet UIView *bottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) OASTrackItem *gpx;
@property (nonatomic) OATargetMenuViewControllerState *targetMenuState;

@end

@implementation OAAddWaypointViewController
{
    OsmAndAppInstance _app;
    OAContextMenuLayer *_contextLayer;
    OAMapRendererView *_mapView;

    BOOL _isCurrentTrack;
    OAGpxWptItem *_movedPoint;
    
    OASGpxFile *_currentGpx;
    
    CGFloat _cachedXViewPort;
    CGFloat _cachedYViewPort;
}

- (instancetype)initWithGpx:(OASTrackItem *)gpx
            targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _gpx = gpx;
        _isCurrentTrack = gpx.isShowCurrentTrack;
        _mapPanelViewController = [OARootViewController instance].mapPanel;
        _contextLayer = _mapPanelViewController.mapViewController.mapLayers.contextMenuLayer;
        _targetMenuState = targetMenuState;
        _mapView = _mapPanelViewController.mapViewController.mapView;
        _cachedXViewPort = _mapView.viewportXScale;
        _cachedYViewPort = _mapView.viewportYScale;
        [_mapPanelViewController.mapViewController setViewportScaleY:kViewportScale];
        [self adjustViewport];
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    OASWptPt *movedPoint = [[OASWptPt alloc] init];
    movedPoint.name = OALocalizedString(@"shared_string_waypoint");
    if (_gpx.isShowCurrentTrack)
    {
        _currentGpx = [OASavingTrackHelper sharedInstance].currentTrack;
        auto rect = _currentGpx.getRect;
        movedPoint.position = CLLocationCoordinate2DMake(rect.centerY, rect.centerX);
    }
    else
    {
        if (!_gpx.dataItem)
        {
            _gpx.dataItem = [[OAGPXDatabase sharedDb] getGPXItem:[OAUtilities getGpxShortPath:_gpx.path]];
        }
        _currentGpx = [OASGpxUtilities.shared loadGpxFileFile:_gpx.dataItem.file];
        
        auto rect = _currentGpx.getRect;
        movedPoint.position = CLLocationCoordinate2DMake(rect.centerY, rect.centerX);
    }
 
    _movedPoint = [OAGpxWptItem withGpxWpt:movedPoint];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _iconView.image = [UIImage templateImageNamed:@"ic_custom_location_marker"];
    _iconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSecondary];
    if (self.delegate)
        [self.delegate requestHeaderOnlyMode];

    OsmAnd::LatLon latLon(_movedPoint.point.position.latitude, _movedPoint.point.position.longitude);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    OAMapViewController *mapVC = _mapPanelViewController.mapViewController;
    [mapVC goToPosition:point andZoom:mapVC.mapView.zoomLevel animated:NO];

    [_contextLayer enterChangePositionMode:_movedPoint];
    _contextLayer.changePositionDelegate = self;

    [self onMapMoved];

    self.coordinatesView.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.cancelButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.addButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void)registerNotifications
{
    [self addNotification:kNotificationSetProfileSetting selector:@selector(onProfileSettingSet:)];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.addButton setTitle:OALocalizedString(@"shared_string_add") forState:UIControlStateNormal];
    _textView.text = _movedPoint.point.name;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (weakSelf.delegate)
            [weakSelf.delegate contentChanged];

        if (![OAUtilities isLandscapeIpadAware])
            [OAUtilities setMaskTo:weakSelf.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        else
            weakSelf.contentView.layer.mask = nil;
        [weakSelf adjustViewport];
    } completion:nil];
}

- (void)adjustViewport
{
    CGFloat viewportXScale = kViewportScale;
    if ([OAUtilities isLandscapeIpadAware])
    {
        CGFloat mapWidth = _mapView.bounds.size.width;
        if (mapWidth <= 0.)
            mapWidth = DeviceScreenWidth;

        CGFloat menuWidth = (OAUtilities.isIPad ? (OAUtilities.isLandscape ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad) : kInfoViewLanscapeWidth) + OAUtilities.getLeftMargin;
        viewportXScale += menuWidth / mapWidth;
    }

    [_mapPanelViewController.mapViewController setViewportScaleX:viewportXScale];
}

- (void)onMenuShown
{
    if (![OAUtilities isLandscapeIpadAware])
        [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
    
    auto rect = _currentGpx.getRect;
    [_mapPanelViewController displayAreaOnMap:CLLocationCoordinate2DMake(rect.top, rect.left)
                                  bottomRight:CLLocationCoordinate2DMake(rect.bottom, rect.right)
                                  bottomInset:([self isLandscape] ? 0. : self.delegate ? self.delegate.getVisibleHeight : 0.)
                                    leftInset:([self isLandscape] ? self.view.frame.size.width : 0.)];
}

- (void)onMenuDismissed
{
    [_contextLayer exitChangePositionMode:_movedPoint applyNewPosition:NO];
    [_mapPanelViewController.mapViewController setViewportScaleX:_cachedXViewPort y:_cachedYViewPort];
}

- (void)onProfileSettingSet:(NSNotification *)notification
{
    // Keep the movable pin centered by ignoring map position changes from rotation mode updates.
    if (notification.object != [OAAppSettings sharedManager].rotateMap)
        return;

    _cachedYViewPort = _mapPanelViewController.mapViewController.mapView.viewportYScale;
    [_mapPanelViewController.mapViewController setViewportScaleY:kViewportScale];
}

- (NSString *)getTypeStr
{
    return nil;
}

- (NSString *)getCommonTypeStr
{
    return @"";
}

- (BOOL)isBottomsControlVisible
{
    return NO;
}

- (BOOL)hasBottomToolbar
{
    return YES;
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (BOOL)needsLayoutOnModeChange
{
    return NO;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (BOOL)offerMapDownload
{
    return NO;
}

- (BOOL)supportFullScreen
{
    return NO;
}

- (BOOL)supportFullMenu
{
    return NO;
}

- (CGFloat)additionalContentOffset
{
    return [OAUtilities isLandscapeIpadAware] ? 0. : [self contentHeight];
}

- (CGFloat)contentHeight
{
    return self.textView.frame.size.height + 8. + self.coordinatesView.frame.size.height + 12. + self.getToolBarHeight;
}

- (UIView *)getMiddleView
{
    return self.contentView;
}

- (UIView *)getBottomView
{
    return self.bottomToolBarView;
}

- (CGFloat)getToolBarHeight
{
    return twoButtonsBottmomSheetHeight;
}

- (IBAction)addPressed:(id)sender
{
    [_contextLayer exitChangePositionMode:_movedPoint applyNewPosition:NO];
    const auto& target = _mapPanelViewController.mapViewController.mapView.target31;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(target);
    [_mapPanelViewController targetPointAddWaypoint:_isCurrentTrack
                    ? nil : [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath]
                                           location:CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude)
                                              title:OALocalizedString(@"shared_string_waypoint")];
}

- (IBAction)cancelPressed:(id)sender
{
    [_contextLayer exitChangePositionMode:_movedPoint applyNewPosition:NO];
    __weak __typeof(self) weakSelf = self;
    [_mapPanelViewController targetHideMenu:0.3 backButtonClicked:YES onComplete:^{
        if ([weakSelf.targetMenuState isKindOfClass:OATrackMenuViewControllerState.class])
        {
            OATrackMenuViewControllerState *state = (OATrackMenuViewControllerState *) weakSelf.targetMenuState;
            state.openedFromTrackMenu = NO;

            [weakSelf.mapPanelViewController openTargetViewWithGPX:weakSelf.gpx
                                              trackHudMode:EOATrackMenuHudMode
                                                     state:state];
        }
    }];

}

#pragma mark - OAChangePositionModeDelegate

- (void)onMapMoved
{
    const auto& target = _mapPanelViewController.mapViewController.mapView.target31;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(target);

    _coordinatesView.text = [OAPointDescription getLocationName:latLon.latitude lon:latLon.longitude sh:YES];
}

@end
