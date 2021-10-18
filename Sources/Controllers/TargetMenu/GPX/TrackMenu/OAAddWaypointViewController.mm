//
//  OAAddWaypointViewController.mm
//  OsmAnd
//
//  Created by Skalii on 12.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAAddWaypointViewController.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAContextMenuLayer.h"
#import "OAMapLayers.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGpxWptItem.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAPointDescription.h"

@interface OAAddWaypointViewController () <OAChangePositionModeDelegate>

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *coordinatesView;

@property (weak, nonatomic) IBOutlet UIView *bottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@end

@implementation OAAddWaypointViewController
{
    OsmAndAppInstance _app;
    OAContextMenuLayer *_contextLayer;
    OAMapPanelViewController *_mapPanelViewController;

    OAGPX *_gpx;
    BOOL _isCurrentTrack;
    OAGpxWptItem *_movedPoint;
    OATargetMenuViewControllerState *_targetMenuState;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
            targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _gpx = gpx;
        _isCurrentTrack = !_gpx || _gpx.gpxFilePath.length == 0 || _gpx.gpxFileName.length == 0;
        _mapPanelViewController = [OARootViewController instance].mapPanel;
        _contextLayer = _mapPanelViewController.mapViewController.mapLayers.contextMenuLayer;
        _targetMenuState = targetMenuState;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    OAGpxWpt *movedPoint = [[OAGpxWpt alloc] init];
    movedPoint.name = OALocalizedString(@"waypoint_one");
    movedPoint.position = _gpx.bounds.center;
    _movedPoint = [OAGpxWptItem withGpxWpt:movedPoint];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.bottomSeparatorHeight.constant = 0.5;
    self.bottomSeparatorTopConstraint.constant = -0.5;

    _iconView.image = [UIImage templateImageNamed:@"ic_action_marker"];
    _iconView.tintColor = UIColorFromRGB(color_tint_gray);

    if (![OAUtilities isLandscapeIpadAware])
        [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];

    [_mapPanelViewController displayGpxOnMap:_gpx];
    if (self.delegate)
        [self.delegate requestHeaderOnlyMode];

    [_contextLayer enterChangePositionMode:_movedPoint];
    _contextLayer.changePositionDelegate = self;

    [self onMapMoved];
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
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.delegate)
            [self.delegate contentChanged];

        if (![OAUtilities isLandscapeIpadAware])
            [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        else
            self.contentView.layer.mask = nil;
    } completion:nil];
}

- (void)onMenuDismissed
{
    [_contextLayer exitChangePositionMode:_movedPoint applyNewPosition:NO];
}

- (NSString *)getTypeStr
{
    return nil;
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
    return 12. + self.textView.frame.size.height + 8. + self.coordinatesView.frame.size.height + 24.;
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
    return 60.;
}

- (IBAction)addPressed:(id)sender
{
    [_contextLayer exitChangePositionMode:_movedPoint applyNewPosition:NO];
    const auto& target = _mapPanelViewController.mapViewController.mapView.target31;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(target);
    [_mapPanelViewController targetPointAddWaypoint:_isCurrentTrack
                    ? nil : [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath]
                                           location:CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude)
                                              title:OALocalizedString(@"waypoint_one")];
}

- (IBAction)cancelPressed:(id)sender
{
    [_contextLayer exitChangePositionMode:_movedPoint applyNewPosition:NO];
    [_mapPanelViewController targetHideMenu:0.3 backButtonClicked:YES onComplete:^{
        [_mapPanelViewController openTargetViewWithGPX:_gpx
                                          trackHudMode:EOATrackMenuHudMode
                                                 state:_targetMenuState];
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
