//
//  OAContextMenuLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAContextMenuLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAMapLayer.h"
#import "OAMapLayers.h"
#import "OAContextMenuProvider.h"
#import "OARootViewController.h"
#import "OAReverseGeocoder.h"
#import "Localization.h"
#import "OAPOILocationType.h"
#import "OAPOI.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/IMapRenderer.h>

@interface OAContextMenuLayer () <CAAnimationDelegate>
@end

@implementation OAContextMenuLayer
{
    // Context pin marker
    std::shared_ptr<OsmAnd::MapMarkersCollection> _contextPinMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _contextPinMarker;
    
    UIImageView *_animatedPin;
    BOOL _animationDone;
    CGFloat _latPin, _lonPin;
    
    BOOL _initDone;
}

- (NSString *) layerId
{
    return kContextMenuLayerId;
}

- (void) initLayer
{
    // Create context pin marker
    _contextPinMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    _contextPinMarker = OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(self.baseOrder)
    .setIsHidden(true)
    .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"ic_map_pin"])
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .buildAndAddToCollection(_contextPinMarkersCollection);

    _initDone = YES;

    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_contextPinMarkersCollection];
    }];
}

- (void) onMapFrameRendered
{
    if (_initDone && _animatedPin)
    {
        if (_animationDone)
        {
            [self hideAnimatedPin];
        }
        else
        {
            CGPoint targetPoint;
            OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_latPin, _lonPin));
            if ([self.mapView convert:&targetPositionI toScreen:&targetPoint])
                _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        }
    }
}

- (std::shared_ptr<OsmAnd::MapMarker>) getContextPinMarker
{
    return _contextPinMarker;
}

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated
{
    if (!_initDone)
        return;
    
    _contextPinMarker->setIsHidden(true);
    
    if (!self.mapView.hidden && animated)
    {
        _animationDone = NO;
        
        _latPin = latitude;
        _lonPin = longitude;
        
        const OsmAnd::LatLon latLon(_latPin, _lonPin);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        
        if (_animatedPin)
            [self hideAnimatedPin];
        
        _animatedPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_map_pin"]];
        
        @try
        {
            CGPoint targetPoint;
            OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(latLon);
            [self.mapView convert:&targetPositionI toScreen:&targetPoint];
            
            _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        }
        @catch (NSException *e)
        {
            _animatedPin = nil;
            _contextPinMarker->setIsHidden(false);
            return;
        }
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                          animationWithKeyPath:@"transform"];
        
        CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
        CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
        CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
        CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
        
        NSArray *frameValues = [NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:scale1],
                                [NSValue valueWithCATransform3D:scale2],
                                [NSValue valueWithCATransform3D:scale3],
                                [NSValue valueWithCATransform3D:scale4],
                                nil];
        [animation setValues:frameValues];
        
        NSArray *frameTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0],
                               [NSNumber numberWithFloat:0.5],
                               [NSNumber numberWithFloat:0.9],
                               [NSNumber numberWithFloat:1.0],
                               nil];
        [animation setKeyTimes:frameTimes];
        
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.duration = .3;
        animation.delegate = self;
        _animatedPin.layer.anchorPoint = CGPointMake(0.5, 1.0);
        [_animatedPin.layer addAnimation:animation forKey:@"popup"];
        
        [self.mapView addSubview:_animatedPin];
    }
    else
    {
        const OsmAnd::LatLon latLon(latitude, longitude);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        _contextPinMarker->setIsHidden(false);
    }
}

- (void) hideContextPinMarker
{
    if (!_initDone)
        return;

    _contextPinMarker->setIsHidden(true);
}

- (void) hideAnimatedPin
{
    if (_animatedPin)
    {
        [_animatedPin.layer removeAllAnimations];
        [_animatedPin removeFromSuperview];
        _animatedPin = nil;
    }
}

- (NSArray<OATargetPoint *> *) selectObjectsForContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation
{
    OAMapRendererView *mapView = self.mapView;
    OAMapViewController *mapViewController = self.mapViewController;
    NSMutableArray<OATargetPoint *> *found = [NSMutableArray array];
    
    OsmAnd::PointI touchLocation;
    [mapView convert:touchPoint toLocation:&touchLocation];
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);
    double lonTap = lon;
    double latTap = lat;

    CGFloat delta = 10.0;
    OsmAnd::AreaI area(OsmAnd::PointI(touchPoint.x - delta, touchPoint.y - delta), OsmAnd::PointI(touchPoint.x + delta, touchPoint.y + delta));

    const auto& symbolInfos = [mapView getSymbolsIn:area strict:NO];
    for (const auto symbolInfo : symbolInfos)
    {
        if (!showUnknownLocation)
        {
            if (const auto billboardMapSymbol = std::dynamic_pointer_cast<const OsmAnd::IBillboardMapSymbol>(symbolInfo.mapSymbol))
            {
                lon = OsmAnd::Utilities::get31LongitudeX(billboardMapSymbol->getPosition31().x);
                lat = OsmAnd::Utilities::get31LatitudeY(billboardMapSymbol->getPosition31().y);
                
                if (const auto billboardAdditionalParams = std::dynamic_pointer_cast<const OsmAnd::MapSymbolsGroup::AdditionalBillboardSymbolInstanceParameters>(symbolInfo.instanceParameters))
                {
                    if (billboardAdditionalParams->overridesPosition31)
                    {
                        lon = OsmAnd::Utilities::get31LongitudeX(billboardAdditionalParams->position31.x);
                        lat = OsmAnd::Utilities::get31LatitudeY(billboardAdditionalParams->position31.y);
                    }
                }
            }
        }
        if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
        {
            if (markerGroup->getMapMarker() == _contextPinMarker.get())
            {
                OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
                targetPoint.type = OATargetContext;
                return @[targetPoint];
            }
        }
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat, lon);
        for (OAMapLayer *layer in [mapViewController.mapLayers getLayers])
        {
            if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
               [((id<OAContextMenuProvider>)layer) collectObjectsFromPoint:coord touchPoint:touchPoint symbolInfo:&symbolInfo found:found unknownLocation:showUnknownLocation];
        }
        
        BOOL gpxModeActive = [[OARootViewController instance].mapPanel gpxModeActive];
        [found sortUsingComparator:^NSComparisonResult(OATargetPoint *obj1, OATargetPoint *obj2) {
            
            double dist1 = OsmAnd::Utilities::distance(lonTap, latTap, obj1.location.longitude, obj1.location.latitude);
            double dist2 = OsmAnd::Utilities::distance(lonTap, latTap, obj2.location.longitude, obj2.location.latitude);
            
            NSInteger index1 = obj1.sortIndex;
            if (gpxModeActive && obj1.type == OATargetWpt)
                index1 = 0;
            
            NSInteger index2 = obj2.sortIndex;
            if (gpxModeActive && obj2.type == OATargetWpt)
                index2 = 0;
            
            if (index1 > OATargetPOI)
                index1 = OATargetPOI;
            if (index2 > OATargetPOI)
                index2 = OATargetPOI;
            
            if (index1 == index2)
            {
                if (dist1 == dist2)
                    return NSOrderedSame;
                else
                    return dist1 < dist2 ? NSOrderedAscending : NSOrderedDescending;
            }
            else
            {
                return index1 < index2 ? NSOrderedAscending : NSOrderedDescending;
            }
        }];
    }
    return found;
}

- (OATargetPoint *) getUnknownTargetPoint:(CGPoint)touchPoint
{
    OAMapRendererView *mapView = self.mapView;
    
    OsmAnd::PointI touchLocation;
    [mapView convert:touchPoint toLocation:&touchLocation];
    double lon = OsmAnd::Utilities::get31LongitudeX(touchLocation.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(touchLocation.y);

    NSString *addressString = nil;
    BOOL isAddressFound = NO;
    NSString *formattedTargetName = nil;
    NSString *roadTitle = [[OAReverseGeocoder instance] lookupAddressAtLat:lat lon:lon];
    if (!roadTitle || roadTitle.length == 0)
    {
        addressString = OALocalizedString(@"map_no_address");
    }
    else
    {
        addressString = roadTitle;
        isAddressFound = YES;
    }
    
    if (isAddressFound || addressString)
    {
        formattedTargetName = addressString;
    }
    else
    {
        formattedTargetName = [[self.app locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    }
    
    OAPOIType *poiType = [[OAPOILocationType alloc] init];
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = lat;
    poi.longitude = lon;
    poi.type = poiType;
    
    if (poi.name.length == 0)
        poi.name = poiType.name;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = poiType.nameLocalized;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = formattedTargetName;
    
    formattedTargetName = poi.nameLocalized;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = formattedTargetName;
    targetPoint.icon = [poiType icon];
    targetPoint.titleAddress = roadTitle;
    targetPoint.type = OATargetPOI;
    targetPoint.targetObj = poi;

    return targetPoint;
}

- (void) showContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation
{
    NSArray<OATargetPoint *> *selectedObjects = [self selectObjectsForContextMenu:touchPoint showUnknownLocation:showUnknownLocation];
    if (showUnknownLocation)
    {
        OATargetPoint *unknownTargetPoint = [self getUnknownTargetPoint:touchPoint];
        [[OARootViewController instance].mapPanel showContextMenu:unknownTargetPoint];
    }
    else if (selectedObjects.count > 0)
    {
        if (selectedObjects[0].type == OATargetContext)
            [[OARootViewController instance].mapPanel reopenContextMenu];
        else
            [[OARootViewController instance].mapPanel showContextMenuWithPoints:selectedObjects];
    }
}

#pragma  mark - CAAnimationDelegate

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _animationDone = YES;
    _contextPinMarker->setIsHidden(false);
}

@end
