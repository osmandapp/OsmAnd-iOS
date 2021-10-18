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
#import "OAPOIHelper.h"
#import "OATransportStop.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/IMapRenderer.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>

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
    
    BOOL _isInChangePositionMode;
    UIImageView *_changePositionPin;
    
    NSArray<NSString *> *_publicTransportTypes;
    
    id<OAMoveObjectProvider> _selectedObjectContextMenuProvider;
    
    NSArray<OAMapLayer *> *_pointLayers;
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

- (BOOL) isObjectMovable:(id)object
{
    for (OAMapLayer *layer in self.mapViewController.mapLayers.getLayers)
    {
        if ([layer conformsToProtocol:@protocol(OAMoveObjectProvider)])
        {
            id<OAMoveObjectProvider> provider = (id<OAMoveObjectProvider>) layer;
            if ([provider isObjectMovable:object])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (void) applyMoveProvider:(id)object
{
    _selectedObjectContextMenuProvider = nil;
    for (OAMapLayer *layer in self.mapViewController.mapLayers.getLayers)
    {
        if ([layer conformsToProtocol:@protocol(OAMoveObjectProvider)])
        {
            id<OAMoveObjectProvider> provider = (id<OAMoveObjectProvider>) layer;
            if ([provider isObjectMovable:object])
            {
                _selectedObjectContextMenuProvider = provider;
                break;
            }
        }
    }
}

- (void) enterChangePositionMode:(id)targetObject
{
    [self applyMoveProvider:targetObject];
    if (!_selectedObjectContextMenuProvider)
        return;
    
    UIImage *icon;
    if ([OARootViewController instance].mapPanel.activeTargetType == OATargetNewMovableWpt)
        icon = [UIImage imageNamed:@"ic_map_pin"];
    else
        icon = [_selectedObjectContextMenuProvider getPointIcon:targetObject];

    [_selectedObjectContextMenuProvider setPointVisibility:targetObject hidden:YES];
    if (!_changePositionPin)
    {
        _changePositionPin = [[UIImageView alloc] initWithImage:icon];
        _changePositionPin.frame = CGRectMake(0., 0., 30., 30.);
        _changePositionPin.contentMode = UIViewContentModeCenter;
    }
    else
    {
        _changePositionPin.image = icon;
    }
    [_changePositionPin sizeToFit];
    
    CGPoint targetPoint;
    OsmAnd::PointI targetPositionI = self.mapView.target31;
    if ([self.mapView convert:&targetPositionI toScreen:&targetPoint])
    {
        CGFloat iconHalfHeight = _changePositionPin.frame.size.height /2;
        CGFloat iconHalfWidth = _changePositionPin.frame.size.width / 2;
        CGFloat shiftX = iconHalfWidth;
        CGFloat shiftY = iconHalfHeight;
        EOAPinVerticalAlignment verticalAlignment = [_selectedObjectContextMenuProvider getPointIconVerticalAlignment];
        EOAPinHorizontalAlignment horizontalAlignment = [_selectedObjectContextMenuProvider getPointIconHorizontalAlignment];
        
        if (horizontalAlignment == EOAPinAlignmentRight)
            shiftX = -iconHalfWidth;
        else if (horizontalAlignment == EOAPinAlignmentCenterHorizontal)
            shiftX = 0;
        
        if (verticalAlignment == EOAPinAlignmentBottom)
            shiftY = -iconHalfHeight;
        else if (verticalAlignment == EOAPinAlignmentCenterVertical)
            shiftY = 0;
        
        _changePositionPin.center = CGPointMake(targetPoint.x - shiftX, targetPoint.y - shiftY);
    }
    
    [self.mapView addSubview:_changePositionPin];
    _isInChangePositionMode = YES;
}

- (void) exitChangePositionMode:(id)targetObject applyNewPosition:(BOOL)applyNewPosition
{
    if (!_isInChangePositionMode)
        return;
    
    if (_changePositionPin && _changePositionPin.superview)
        [_changePositionPin removeFromSuperview];
    
    if (_selectedObjectContextMenuProvider)
    {
        if (applyNewPosition)
        {
            const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(self.mapView.target31);
            [_selectedObjectContextMenuProvider applyNewObjectPosition:targetObject position:CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude)];
        }
        else
        {
            [_selectedObjectContextMenuProvider setPointVisibility:targetObject hidden:NO];
        }
    }
    _selectedObjectContextMenuProvider = nil;
    _isInChangePositionMode = NO;
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
    
    if (_isInChangePositionMode && self.changePositionDelegate)
        [self.changePositionDelegate onMapMoved];
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

- (OATargetPoint *) getTargetPoint:(id)obj
{
    OAMapViewController *mapViewController = self.mapViewController;
    for (OAMapLayer *layer in [mapViewController.mapLayers getLayers])
    {
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            OATargetPoint *targetPoint = [((id<OAContextMenuProvider>)layer) getTargetPoint:obj];
            if (targetPoint)
                return targetPoint;
        }
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    OAMapViewController *mapViewController = self.mapViewController;
    for (OAMapLayer *layer in [mapViewController.mapLayers getLayers])
    {
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            OATargetPoint *targetPoint = [((id<OAContextMenuProvider>)layer) getTargetPointCpp:obj];
            if (targetPoint)
                return targetPoint;
        }
    }
    return nil;
}

- (NSArray<OATargetPoint *> *) selectObjectsForContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation
{
    OAMapRendererView *mapView = self.mapView;
    OAMapViewController *mapViewController = self.mapViewController;
    NSMutableArray<OATargetPoint *> *found = [NSMutableArray array];
    
    CLLocationCoordinate2D coord = [self getTouchPointCoord:touchPoint];
    double lat = coord.latitude;
    double lon = coord.longitude;
    double latTap = lat;
    double lonTap = lon;
    
    CLLocationCoordinate2D objectCoord = kCLLocationCoordinate2DInvalid;
    CGFloat delta = 10.0;
    OsmAnd::AreaI area(OsmAnd::PointI(touchPoint.x - delta, touchPoint.y - delta), OsmAnd::PointI(touchPoint.x + delta, touchPoint.y + delta));

    const auto& symbolInfos = [mapView getSymbolsIn:area strict:NO];
    NSString *roadTitle = [[OAReverseGeocoder instance] lookupAddressAtLat:lat lon:lon];

    if (!_pointLayers)
    {
        _pointLayers = @[self.mapViewController.mapLayers.myPositionLayer,
                         self.mapViewController.mapLayers.mapillaryLayer,
                         self.mapViewController.mapLayers.downloadedRegionsLayer];
    }
    for (OAMapLayer *layer in _pointLayers)
    {
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
           [((id<OAContextMenuProvider>)layer) collectObjectsFromPoint:coord touchPoint:touchPoint symbolInfo:nil found:found unknownLocation:showUnknownLocation];
    }
    NSMutableArray<OAMapLayer *> *layers = [[mapViewController.mapLayers getLayers] mutableCopy];
    [layers removeObjectsInArray:_pointLayers];

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
                objectCoord = CLLocationCoordinate2DMake(lat, lon);
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
        for (OAMapLayer *layer in layers)
        {
            if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
               [((id<OAContextMenuProvider>)layer) collectObjectsFromPoint:coord touchPoint:touchPoint symbolInfo:&symbolInfo found:found unknownLocation:showUnknownLocation];
        }
    }
    
    if (found.count > 0)
    {
        if (found.count > 1)
        {
            // Sometimes there appears two copy of one point. We decided to filter it right here (in UI).
            // https://github.com/osmandapp/OsmAnd-Issues/issues/533
            
            NSMutableSet<OATargetPoint *> *filtredPointsSet = [NSMutableSet new];
            for (OATargetPoint *point in found)
                [filtredPointsSet addObject:point];
            found = [NSMutableArray arrayWithArray:filtredPointsSet.allObjects];
        }
        
        NSMutableArray *existingPoints = [NSMutableArray array];
        for (OATargetPoint *targetPoint in found)
        {
            NSString *formattedTargetName = nil;
            NSString *addressString = nil;
            OAPOI *poi = [targetPoint.targetObj isKindOfClass:[OAPOI class]] ? (OAPOI *)targetPoint.targetObj : nil;
            if (poi)
            {
                for (OATargetPoint *targetPoint in found)
                {
                    OATransportStop *transportStop = [targetPoint.targetObj isKindOfClass:[OATransportStop class]] ? (OATransportStop *)targetPoint.targetObj : nil;
                    if (transportStop && [poi.name isEqualToString:transportStop.name])
                    {
                        transportStop.poi = poi;
                        [existingPoints addObject:targetPoint];
                        break;
                    }
                }
            }
            
            OAPOIType *poiType = poi ? poi.type : nil;
            NSString *buildingNumber = poi ? poi.buildingNumber : nil;
            BOOL needAddress = YES;
            BOOL isAddressFound = NO;
            if (poiType)
                needAddress = ![@"place" isEqualToString:poiType.tag];

            NSString *caption = targetPoint.title;
            if (caption.length == 0 && (targetPoint.type == OATargetLocation || targetPoint.type == OATargetPOI))
            {
                if (!roadTitle || roadTitle.length == 0)
                {
                    if (buildingNumber.length > 0)
                    {
                        addressString = buildingNumber;
                        isAddressFound = YES;
                    }
                    else
                    {
                        addressString = OALocalizedString(@"map_no_address");
                    }
                }
                else
                {
                    addressString = roadTitle;
                    isAddressFound = YES;
                }
            }
            else if (caption.length > 0)
            {
                isAddressFound = YES;
                addressString = caption;
            }
            
            if (isAddressFound || addressString)
            {
                formattedTargetName = addressString;
            }
            else if (poiType)
            {
                isAddressFound = YES;
                formattedTargetName = poiType.nameLocalized;
            }
            else if (buildingNumber.length > 0)
            {
                isAddressFound = YES;
                formattedTargetName = buildingNumber;
            }
            else
            {
                formattedTargetName = [OAPointDescription getLocationName:targetPoint.location.latitude lon:targetPoint.location.longitude sh:NO];
            }

            if (poi && poi.nameLocalized.length == 0)
                poi.nameLocalized = formattedTargetName;
            
            targetPoint.title = formattedTargetName;
            targetPoint.addressFound = isAddressFound;
            targetPoint.titleAddress = needAddress ? roadTitle : nil;
        }
        if (existingPoints.count > 0)
            [found removeObjectsInArray:existingPoints];
        
        [self processTransportStops:found coord:coord];

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
    
    if (found.count == 1 && CLLocationCoordinate2DIsValid(objectCoord))
        found[0].location = objectCoord;
    
    return found;
}

- (OATargetPoint *) getUnknownTargetPoint:(double)latitude longitude:(double)longitude
{
    NSString *addressString = nil;
    BOOL isAddressFound = NO;
    NSString *formattedTargetName = nil;
    NSString *roadTitle = [[OAReverseGeocoder instance] lookupAddressAtLat:latitude lon:longitude];
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
        formattedTargetName = [OAPointDescription getLocationName:latitude lon:longitude sh:NO];
    }
    
    OAPOIType *poiType = [[OAPOILocationType alloc] init];
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = latitude;
    poi.longitude = longitude;
    poi.type = poiType;
    
    if (poi.name.length == 0)
        poi.name = poiType.name;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = poiType.nameLocalized;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = formattedTargetName;
    
    formattedTargetName = poi.nameLocalized;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.location = CLLocationCoordinate2DMake(latitude, longitude);
    targetPoint.title = formattedTargetName;
    targetPoint.icon = [poiType icon];
    targetPoint.titleAddress = roadTitle;
    targetPoint.type = OATargetPOI;
    targetPoint.targetObj = poi;

    return targetPoint;
}

- (void) showContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation forceHide:(BOOL)forceHide
{
    NSArray<OATargetPoint *> *selectedObjects = [self selectObjectsForContextMenu:touchPoint showUnknownLocation:showUnknownLocation];
    if (selectedObjects.count > 0)
    {
        if (selectedObjects[0].type == OATargetContext)
            [[OARootViewController instance].mapPanel reopenContextMenu];
        else
            [[OARootViewController instance].mapPanel showContextMenuWithPoints:selectedObjects];
    }
    else if (showUnknownLocation)
    {
        CLLocationCoordinate2D coord = [self getTouchPointCoord:touchPoint];
        OATargetPoint *unknownTargetPoint = [self getUnknownTargetPoint:coord.latitude longitude:coord.longitude];
        [[OARootViewController instance].mapPanel showContextMenu:unknownTargetPoint];
    }
    else
    {
        CLLocationCoordinate2D coord = [self getTouchPointCoord:touchPoint];
        [[OARootViewController instance].mapPanel processNoSymbolFound:coord forceHide:forceHide];
    }
}

- (NSArray<NSString *> *) getPublicTransportTypes
{
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    if (!_publicTransportTypes)
    {
        OAPOICategory *category = [poiHelper getPoiCategoryByName:@"transportation"];
        if (category)
        {
            NSArray<OAPOIFilter *> *filters = category.poiFilters;
            NSMutableArray *publicTransportTypes = [NSMutableArray array];
            for (OAPOIFilter *poiFilter in filters)
            {
                if ([poiFilter.name isEqualToString:@"public_transport"])
                {
                    for (OAPOIType *poiType in poiFilter.poiTypes)
                    {
                        [publicTransportTypes addObject:poiType.name];
                        for (OAPOIType *poiAdditionalType in poiType.poiAdditionals)
                            [publicTransportTypes addObject:poiAdditionalType.name];
                    }
                }
            }
            _publicTransportTypes = [NSArray arrayWithArray:publicTransportTypes];
        }
    }
    return _publicTransportTypes;
}

- (NSArray<OATransportStop *> *) findTransportStopsAt:(CLLocationCoordinate2D)coord
{
    NSMutableArray<OATransportStop *> *transportStops = [NSMutableArray array];
    
    const std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>(new OsmAnd::TransportStopsInAreaSearch::Criteria);
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(coord.latitude, coord.longitude));
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(kShowStopsRadiusMeters, point31);
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const auto search = std::make_shared<const OsmAnd::TransportStopsInAreaSearch>(obfsCollection);
    search->performSearch(*searchCriteria,
                          [self, transportStops]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                              const auto transportStop = ((OsmAnd::TransportStopsInAreaSearch::ResultEntry&)resultEntry).transportStop;
                              OATransportStop *stop = [[OATransportStop alloc] init];
                              stop.stop = transportStop;
                              [transportStops addObject:stop];
                          });
    
    return transportStops;
}

- (void) sortTransportStops:(CLLocationCoordinate2D)coord transportStops:(NSMutableArray<OATransportStop *> *)transportStops
{
    for (OATransportStop *transportStop in transportStops)
        transportStop.distance = OsmAnd::Utilities::distance(coord.longitude, coord.latitude, transportStop.location.longitude, transportStop.location.latitude);

    [transportStops sortUsingComparator:^NSComparisonResult(OATransportStop * _Nonnull s1, OATransportStop * _Nonnull s2) {
        return [OAUtilities compareInt:s1.distance y:s2.distance];
    }];
}

- (void) processTransportStops:(NSMutableArray<OATargetPoint *> *)selectedObjects coord:(CLLocationCoordinate2D)coord
{
    NSArray<NSString *> *publicTransportTypes = [self getPublicTransportTypes];
    if (publicTransportTypes)
    {
        NSMutableArray<OATargetPoint *> *transportStopPOIs = [NSMutableArray array];
        for (OATargetPoint *point in selectedObjects)
        {
            id o = point.targetObj;
            if ([o isKindOfClass:[OAPOI class]])
            {
                OAPOI *poi = (OAPOI *)o;
                if (poi.type.name.length > 0 && [publicTransportTypes containsObject:poi.type.name])
                    [transportStopPOIs addObject:point];
            }
        }
        if (transportStopPOIs.count > 0)
        {
            NSArray<OATransportStop *> *transportStops = [self findTransportStopsAt:coord];
            NSMutableArray<OATransportStop *> *transportStopsReplacement = [NSMutableArray array];
            for (OATargetPoint *point in transportStopPOIs)
            {
                OAPOI *poi = (OAPOI *)point.targetObj;
                NSMutableArray<OATransportStop *> *poiTransportStops = [NSMutableArray array];
                for (OATransportStop *transportStop in transportStops)
                {
                    if ([transportStop.name hasPrefix:poi.name])
                    {
                        [poiTransportStops addObject:transportStop];
                        transportStop.poi = poi;
                    }
                }
                if (poiTransportStops.count > 0)
                {
                    [selectedObjects removeObject:point];
                    if (poiTransportStops.count > 1)
                        [self sortTransportStops:CLLocationCoordinate2DMake(poi.latitude, poi.longitude) transportStops:poiTransportStops];

                    OATransportStop *poiTransportStop = poiTransportStops[0];
                    if (![transportStopsReplacement containsObject:poiTransportStop])
                        [transportStopsReplacement addObject:poiTransportStop];
                }
            }
            if (transportStopsReplacement.count > 0)
            {
                OAMapViewController *mapViewController = self.mapViewController;
                for (OATransportStop *transportStop in transportStopsReplacement)
                    [selectedObjects addObject:[mapViewController.mapLayers.transportStopsLayer getTargetPoint:transportStop]];
            }
        }
    }
}

#pragma  mark - CAAnimationDelegate

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _animationDone = YES;
    _contextPinMarker->setIsHidden(false);
}

@end
