//
//  OAChangePositionViewController.m
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAChangePositionViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
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

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/GeoInfoDocument.h>

@interface OAChangePositionViewController () <OAChangePositionModeDelegate>

@end

@implementation OAChangePositionViewController
{
    OsmAndAppInstance _app;
    
    OATargetPoint *_targetPoint;
    
    OAMapLayers *_mapLayers;
    OAContextMenuLayer *_contextLayer;
    
    std::shared_ptr<OsmAnd::IFavoriteLocation> _favoriteLocation;
    
    int _intermediateIndex;
}

-(instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _targetPoint = targetPoint;
        _mapLayers = OARootViewController.instance.mapPanel.mapViewController.mapLayers;
        _contextLayer = _mapLayers.contextMenuLayer;
        _intermediateIndex = -1;
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

- (UIImage *) getCorrectIcon
{
    switch (_targetPoint.type)
    {
        case OATargetRouteStart:
            return [UIImage imageNamed:@"map_start_point"];
        case OATargetRouteIntermediate:
            return [UIImage imageNamed:@"map_intermediate_point"];
        case OATargetRouteFinish:
            return [UIImage imageNamed:@"map_target_point"];
        case OATargetOsmEdit:
        case OATargetOsmNote:
            return [UIImage imageNamed:@"map_osm_edit"];
        case OATargetParking:
            return [UIImage imageNamed:@"map_parking_pin"];
            
        default:
            return _targetPoint.icon;
    }
}

- (void) updateActualPointVisibility:(BOOL)hidden
{
    switch (_targetPoint.type)
    {
        case OATargetRouteStart:
        {
            [_mapLayers.routePointsLayer setStartMarkerVisibility:hidden];
            break;
        }
        case OATargetRouteIntermediate:
        {
            OARTargetPoint *target = _targetPoint.targetObj;
            _intermediateIndex = target.index;
            [_mapLayers.routePointsLayer setIntermediateMarkerVisibility:CLLocationCoordinate2DMake(target.getLatitude, target.getLongitude) hidden:hidden];
            break;
        }
        case OATargetRouteFinish:
        {
            [_mapLayers.routePointsLayer setFinishMarkerVisibility:hidden];
            break;
        }
        case OATargetOsmEdit:
        case OATargetOsmNote:
        {
            [_mapLayers.osmEditsLayer setPointVisibility:_targetPoint.targetObj hidden:hidden];
            break;
        }
        case OATargetFavorite:
        {
            if (_favoriteLocation != nullptr)
            {
                [_mapLayers.favoritesLayer setPointVisibility:@[@(_favoriteLocation->getPosition31().x), @(_favoriteLocation->getPosition31().y)] hidden:hidden];
            }
            break;
        }
        case OATargetParking:
        case OATargetDestination:
        {
            [_mapLayers.destinationsLayer setPointVisibility:_targetPoint.targetObj hidden:hidden];
            break;
        }
        case OATargetWpt:
        {
            OAGpxWptItem *item = _targetPoint.targetObj;
            if (item.docPath)
                [_mapLayers.gpxMapLayer setPointVisibility:item hidden:hidden];
            else
                [_mapLayers.gpxRecMapLayer setPointVisibility:item hidden:hidden];
            break;
        }
        case OATargetImpassableRoad:
        {
            [_mapLayers.impassableRoadsLayer setPointVisibility:_targetPoint.targetObj hidden:hidden];
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void) findFavoriteLocation
{
    _favoriteLocation = nullptr;
    OsmAndAppInstance app = _app;
    OsmAnd::LatLon favLocation = OsmAnd::LatLon(_targetPoint.location.latitude, _targetPoint.location.longitude);
    for (const auto& fav : app.favoritesCollection->getFavoriteLocations())
    {
        if (fav->getLatLon() == favLocation)
            _favoriteLocation = fav;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_targetPoint.type == OATargetFavorite)
        [self findFavoriteLocation];
    
    [_contextLayer enterChangePositionMode:[self getCorrectIcon]];
    _contextLayer.changePositionDelegate = self;
    [self updateActualPointVisibility:YES];
    
    CGRect bottomDividerFrame = _bottomToolBarDividerView.frame;
    bottomDividerFrame.size.height = 0.5;
    _bottomToolBarDividerView.frame = bottomDividerFrame;
    
    _iconView.image = _targetPoint.icon;
    
    if (!self.isLandscape)
    {
        [OAUtilities setMaskTo:_mainTitleContainerView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    
    OsmAnd::LatLon latLon(_targetPoint.location.latitude, _targetPoint.location.longitude);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];

    OAMapViewController *mapVC = OARootViewController.instance.mapPanel.mapViewController;
    [mapVC goToPosition:point andZoom:mapVC.mapView.zoomLevel animated:NO];
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
    return [self isLandscape] ? 0. : [self contentHeight];
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

- (void)onMenuDismissed
{
    [self updateActualPointVisibility:NO];
    [_contextLayer exitChangePositionMode];
}

- (void) applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    _itemTitleView.text = _targetPoint.title;
    _typeView.text = [self getLocalizedType];
    _mainTitleView.text = OALocalizedString(@"change_position_descr");
}

- (NSString *) getLocalizedType
{
    switch (_targetPoint.type)
    {
        case OATargetFavorite:
            return OALocalizedString(@"favorite");
        case OATargetOsmEdit:
            return OALocalizedString(@"osm_edit");
        case OATargetOsmNote:
            return OALocalizedString(@"osm_note");
        case OATargetRouteStart:
            return OALocalizedString(@"route_start_point");
        case OATargetRouteIntermediate:
            return OALocalizedString(@"route_intermediate");
        case OATargetRouteFinish:
            return OALocalizedString(@"route_end_point");
        case OATargetParking:
            return OALocalizedString(@"parking");
        case OATargetWpt:
        {
            OAGpxWptItem *item = _targetPoint.targetObj;
            return item.point.type && item.point.type.length > 0 ? item.point.type : OALocalizedString(@"gpx_waypoint");
        }
        case OATargetImpassableRoad:
            return OALocalizedString(@"blocked_road_type");
        case OATargetDestination:
            return OALocalizedString(@"ctx_mnu_direction");
            
        default:
            return @"";
    }
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
        
        if (!self.isLandscape)
        {
            [OAUtilities setMaskTo:_mainTitleContainerView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
            [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        }
        else
        {
            _mainTitleContainerView.layer.mask = nil;
            self.contentView.layer.mask = nil;
        }
    } completion:nil];
}

- (IBAction)buttonDonePressed:(id)sender
{
    const auto& coord = OsmAnd::Utilities::convert31ToLatLon(OARootViewController.instance.mapPanel.mapViewController.mapView.target31);
    switch (_targetPoint.type)
    {
        case OATargetRouteStart:
        {
            [[OATargetPointsHelper sharedInstance] setStartPoint:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] updateRoute:YES name:nil];
            break;
        }
        case OATargetRouteIntermediate:
        {
            OATargetPointsHelper *targetHelper = [OATargetPointsHelper sharedInstance];
            if (_intermediateIndex != -1)
            {
                [targetHelper removeWayPoint:YES index:_intermediateIndex];
                [targetHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] updateRoute:YES intermediate:_intermediateIndex];
            }
            break;
        }
        case OATargetRouteFinish:
        {
            [[OATargetPointsHelper sharedInstance] navigateToPoint:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] updateRoute:YES intermediate:-1];
            break;
        }
        case OATargetOsmEdit:
        {
            OAOpenStreetMapPoint *point = _targetPoint.targetObj;
            [[OAOsmEditsDBHelper sharedDatabase] updateEditLocation:point.getId newPosition:CLLocationCoordinate2DMake(coord.latitude, coord.longitude)];
            [_app.osmEditsChangeObservable notifyEvent];
            break;
        }
        case OATargetOsmNote:
        {
            OAOsmNotePoint *point = _targetPoint.targetObj;
            [[OAOsmBugsDBHelper sharedDatabase] updateOsmBugLocation:point.getId newPosition:CLLocationCoordinate2DMake(coord.latitude, coord.longitude)];
            [_app.osmEditsChangeObservable notifyEvent];
            break;
        }
        case OATargetFavorite:
        {
            if (_favoriteLocation != nullptr)
            {
                _app.favoritesCollection->removeFavoriteLocation(_favoriteLocation);
                _app.favoritesCollection->createFavoriteLocation(OsmAnd::Utilities::convertLatLonTo31(coord),
                                                                _favoriteLocation->getTitle(),
                                                                _favoriteLocation->getGroup(),
                                                                _favoriteLocation->getColor());
            }
            break;
        }
        case OATargetParking:
        case OATargetDestination:
        {
            OADestination *dest = _targetPoint.targetObj;
            OADestinationsHelper *helper = [OADestinationsHelper instance];
            [helper removeDestination:dest];
            dest.latitude = coord.latitude;
            dest.longitude = coord.longitude;
            [helper addDestination:dest];
            
            break;
        }
        case OATargetWpt:
        {
            OAGpxWptItem *item = _targetPoint.targetObj;
            if (item.docPath)
            {
                item.point.position = CLLocationCoordinate2DMake(coord.latitude, coord.longitude);
                item.point.wpt->position = coord;
                const auto activeGpx = [OASelectedGPXHelper instance].activeGpx;
                const auto& doc = std::dynamic_pointer_cast<const OsmAnd::GpxDocument>(activeGpx[QString::fromNSString(item.docPath)]);
                if (doc != nullptr)
                    doc->saveTo(QString::fromNSString(item.docPath));
                
                [_app.updateGpxTracksOnMapObservable notifyEvent];
            }
            else
            {
                OASavingTrackHelper *helper = [OASavingTrackHelper sharedInstance];
                [helper updatePointCoordinates:item.point newLocation:CLLocationCoordinate2DMake(coord.latitude, coord.longitude)];
                item.point.wpt->position = coord;
                [_app.trackRecordingObservable notifyEventWithKey:@(YES)];
            }
            
            break;
        }
        case OATargetImpassableRoad:
        {
            OAAvoidSpecificRoads *avoidRoads = [OAAvoidSpecificRoads instance];
            NSNumber* roadId = _targetPoint.targetObj;
            const auto& road = [avoidRoads getRoadById:roadId.unsignedLongLongValue];
            [avoidRoads removeImpassableRoad:road];
            [avoidRoads addImpassableRoad:[[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude] showDialog:NO skipWritingSettings:NO];
            break;
        }
        default:
        {
            break;
        }
    }
    [_contextLayer exitChangePositionMode];
    [[OARootViewController instance].mapPanel hideContextMenu];
}

- (IBAction)cancelPressed:(id)sender
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [self updateActualPointVisibility:NO];
    [mapPanel showContextMenu:_targetPoint];
    [_contextLayer exitChangePositionMode];
}

#pragma mark - OAChangePositionModeDelegate

- (void) onMapMoved
{
    const auto& target = OARootViewController.instance.mapPanel.mapViewController.mapView.target31;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(target);
    
    _coordinatesView.text = [OAPointDescription getLocationName:latLon.latitude lon:latLon.longitude sh:YES];
}

@end
