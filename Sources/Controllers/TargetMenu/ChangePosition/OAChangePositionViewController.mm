//
//  OAChangePositionViewController.m
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAChangePositionViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OANativeUtilities.h"
#import "OAContextMenuLayer.h"
#import "OAMapLayers.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmNotePoint.h"
#import "OARTargetPoint.h"
#import "OARoutePointsLayer.h"
#import "OAOsmEditsLayer.h"
#import "OATargetPointsHelper.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OADestination.h"
#import "OAGpxWptItem.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAAvoidSpecificRoads.h"
#import "OADestinationsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDocument.h"
#import "OAPointDescription.h"
#import "OAFavoriteItem.h"

#import <OsmAndCore/Utilities.h>

#define kAdjustedViewportScale 1.5
#define kRegularViewportScale 1.0

@interface OAChangePositionViewController () <OAChangePositionModeDelegate>

@end

@implementation OAChangePositionViewController
{
    OsmAndAppInstance _app;
    
    OATargetPoint *_targetPoint;
    
    OAContextMenuLayer *_contextLayer;
    OAMapRendererView *_mapView;
    
    CGFloat _cachedX;
    CGFloat _cachedY;
}

-(instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _targetPoint = targetPoint;
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        _contextLayer = mapPanel.mapViewController.mapLayers.contextMenuLayer;
        _mapView = mapPanel.mapViewController.mapView;
        _cachedX = _mapView.viewportXScale;
        _cachedY = _mapView.viewportYScale;
        [mapPanel.mapViewController setViewportScaleY:kRegularViewportScale];
        [self adjustViewport];
    }
    return self;
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (NSAttributedString *)getAttributedTypeStr
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (NSString *)getTypeStr
{
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_contextLayer enterChangePositionMode:_targetPoint.targetObj];
    _contextLayer.changePositionDelegate = self;
    
    CGRect bottomDividerFrame = _bottomToolBarDividerView.frame;
    bottomDividerFrame.size.height = 0.5;
    _bottomToolBarDividerView.frame = bottomDividerFrame;
    
    if ([_targetPoint.targetObj isKindOfClass:OAFavoriteItem.class])
    {
        OAFavoriteItem *favorite = (OAFavoriteItem *)_targetPoint.targetObj;
        _iconView.image = [favorite getCompositeIcon];   
    }
    else
    {
        _iconView.image = _targetPoint.icon;
    }
    
    if (![OAUtilities isLandscapeIpadAware])
    {
        [OAUtilities setMaskTo:_mainTitleContainerView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    
    OsmAnd::LatLon latLon(_targetPoint.location.latitude, _targetPoint.location.longitude);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];

    OAMapViewController *mapVC = OARootViewController.instance.mapPanel.mapViewController;
    [mapVC goToPosition:point andZoom:mapVC.mapView.zoomLevel animated:NO];
    
    [self onMapMoved];

    self.coordinatesView.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.cancelButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.doneButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    CGFloat w = width - 32.0 - OAUtilities.getLeftMargin;
    CGRect leftBtnFrame = _cancelButton.frame;
    CGRect rightBtnFrame = _doneButton.frame;

    if (_doneButton.isDirectionRTL)
    {
        rightBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        rightBtnFrame.size.width = w / 2 - 8;
        
        leftBtnFrame.origin.x = CGRectGetMaxX(rightBtnFrame) + 16.;
        leftBtnFrame.size.width = rightBtnFrame.size.width;
        
        _cancelButton.frame = leftBtnFrame;
        _doneButton.frame = rightBtnFrame;
    }
    else
    {
        leftBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
        leftBtnFrame.size.width = w / 2 - 8;
        _cancelButton.frame = leftBtnFrame;
        
        rightBtnFrame.origin.x = CGRectGetMaxX(leftBtnFrame) + 16.;
        rightBtnFrame.size.width = leftBtnFrame.size.width;
        _doneButton.frame = rightBtnFrame;
    }
    
    _cancelButton.layer.cornerRadius = 9.;
    _doneButton.layer.cornerRadius = 9.;
}

- (void)adjustViewport
{
    [[OARootViewController instance].mapPanel.mapViewController setViewportScaleX:[OAUtilities isLandscapeIpadAware] ? kAdjustedViewportScale : kRegularViewportScale];
}

- (UIView *) getMiddleView
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

- (CGFloat) additionalContentOffset
{
    return [OAUtilities isLandscapeIpadAware] ? 0. : [self contentHeight];
}

- (BOOL)hasBottomToolbar
{
    return YES;
}

- (BOOL) needsLayoutOnModeChange
{
    return NO;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return NO;
}

- (BOOL)supportFullMenu
{
    return NO;
}

- (BOOL)hideButtons
{
    return YES;
}

- (BOOL)offerMapDownload
{
    return NO;
}

- (void)onMenuDismissed
{
    [_contextLayer exitChangePositionMode:_targetPoint.targetObj applyNewPosition:NO];
    [[OARootViewController instance].mapPanel.mapViewController setViewportScaleX:_cachedX y:_cachedY];
}

- (void) applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    _itemTitleView.text = _targetPoint.title;
    _typeView.text = _targetPoint.ctrlTypeStr;
    _mainTitleView.text = OALocalizedString(@"move_marker_bottom_sheet_title");
}

- (CGFloat)contentHeight
{
    return _mainTitleView.frame.size.height + 14. + _itemTitleView.frame.size.height + 5. + _typeView.frame.size.height + 10. + _coordinatesView.frame.size.height + 12. + self.getToolBarHeight;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.delegate)
            [self.delegate contentChanged];
        
        if (![OAUtilities isLandscapeIpadAware])
        {
            [OAUtilities setMaskTo:_mainTitleContainerView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
            [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        }
        else
        {
            _mainTitleContainerView.layer.mask = nil;
            self.contentView.layer.mask = nil;
        }
        [self adjustViewport];
    } completion:nil];
}

- (IBAction)buttonDonePressed:(id)sender
{
    [_contextLayer exitChangePositionMode:_targetPoint.targetObj applyNewPosition:YES];
    [[OARootViewController instance].mapPanel hideContextMenu];
}

- (IBAction)cancelPressed:(id)sender
{
    [_contextLayer exitChangePositionMode:_targetPoint.targetObj applyNewPosition:NO];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel showContextMenu:_targetPoint];
}

#pragma mark - OAChangePositionModeDelegate

- (void) onMapMoved
{
    const auto& target = _mapView.target31;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(target);
    
    _coordinatesView.text = [OAPointDescription getLocationName:latLon.latitude lon:latLon.longitude sh:YES];
}

@end
