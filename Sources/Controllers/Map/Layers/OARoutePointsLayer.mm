//
//  OARoutePointsLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePointsLayer.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAStateChangedListener.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"
#import "OATargetPointsHelper.h"
#import "OAMapSelectionResult.h"
#import "Localization.h"

#include <SkCGUtils.h>
#include <SkImage.h>

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/SingleSkImage.h>

@interface OARoutePointsLayer () <OAStateChangedListener>

@end

@implementation OARoutePointsLayer
{
    OATargetPointsHelper *_targetPoints;
    
    // Markers
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _startPointMarker;
    std::shared_ptr<OsmAnd::MapMarker> _targetPointMarker;
    QList<std::shared_ptr<OsmAnd::MapMarker>> _intermediatePointMarkers;
}

- (NSString *) layerId
{
    return kRoutePointsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _targetPoints = [OATargetPointsHelper sharedInstance];
    [self updatePoints];
    [_targetPoints addListener:self];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    [_targetPoints removeListener:self];
}

- (void) resetPoints
{
    if (_markersCollection)
        [self.mapView removeKeyedSymbolsProvider:_markersCollection];
    
    _markersCollection.reset(new OsmAnd::MapMarkersCollection());
}

- (void) setupPoints
{
    OARTargetPoint *pointToStart = [_targetPoints getPointToStart];
    if (pointToStart)
    {
        const OsmAnd::LatLon latLon([pointToStart getLatitude], [pointToStart getLongitude]);
        _startPointMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.pointsOrder)
        .setIsHidden(false)
        .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromPngResource:@"map_start_point"]))
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
        .buildAndAddToCollection(_markersCollection);
    }
    
    for (OARTargetPoint *point in [_targetPoints getIntermediatePoints])
    {
        const OsmAnd::LatLon latLon([point getLatitude], [point getLongitude]);
        _targetPointMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.pointsOrder + 1)
        .setIsHidden(false)
        .setPinIcon(OsmAnd::SingleSkImage([self getIntermediateImage:point]))
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
        .buildAndAddToCollection(_markersCollection);
    }
    
    OARTargetPoint *pointToNavigate = [_targetPoints getPointToNavigate];
    if (pointToNavigate)
    {
        const OsmAnd::LatLon latLon([pointToNavigate getLatitude], [pointToNavigate getLongitude]);
        _targetPointMarker = OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.pointsOrder + 2)
        .setIsHidden(false)
        .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromPngResource:@"map_target_point"]))
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
        .buildAndAddToCollection(_markersCollection);
    }
    
    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_markersCollection];
    }];
}

- (UIImage *) getIntermediateUIImage:(int)index
{
    UIImage *flagImage = [UIImage imageNamed:@"map_intermediate_point"];
    if (flagImage)
    {
        UIGraphicsBeginImageContextWithOptions(flagImage.size, NO, [UIScreen mainScreen].scale);
        
        [flagImage drawAtPoint:{0, 0}];
        
        NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor;
        UIFont *font = [UIFont scaledSystemFontOfSize:18.0];
        attributes[NSFontAttributeName] = font;
        
        CGFloat w2 = flagImage.size.width / 2.0;
        CGFloat h2 = flagImage.size.height / 2.0;
        CGFloat textH = font.lineHeight;
        CGFloat textY = (h2 - textH) / 2.0 + 1.0;
        CGRect textRect = CGRectMake(w2, textY, w2 - 6.0, textH);
        [[NSString stringWithFormat:@"%d", index] drawInRect:textRect withAttributes:attributes];
        
        flagImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return flagImage;
}

- (sk_sp<SkImage>) getIntermediateImage:(OARTargetPoint *)point
{
    @autoreleasepool
    {
        UIImage *image = [self getIntermediateUIImage:point.index + 1];
        return image ? SkMakeImageFromCGImage(image.CGImage) : nullptr;
    }
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getRouteMarkersCollection
{
    return _markersCollection;
}

- (void) updatePoints
{
    [self.mapViewController runWithRenderSync:^{
        
        [self resetPoints];
        [self setupPoints];
    }];
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    if ([change boolValue])
        [self updatePoints];
}

#pragma mark - OAContextMenuProvider

- (void) collectObjectsFromPoint:(OAMapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    if ([self.mapViewController getMapZoom] >= 3 && !excludeUntouchableObjects)
    {
        CGPoint point = [result getPoint];
        int radius = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
        OsmAnd::AreaI touchPolygon31 = [OANativeUtilities getPolygon31FromPixelAndRadius:point radius:radius];
        if (touchPolygon31 == OsmAnd::AreaI())
            return;
        
        for (const auto& routePoint : _markersCollection->getMarkers())
        {
            double lat = OsmAnd::Utilities::get31LatitudeY(routePoint->getPosition().y);
            double lon = OsmAnd::Utilities::get31LongitudeX(routePoint->getPosition().x);
            
            BOOL shouldAdd = [OANativeUtilities isPointInsidePolygon:lat lon:lon polygon31:touchPolygon31];
            if (shouldAdd)
            {
                OAMapMarkerWrapper *wrapper = [[OAMapMarkerWrapper alloc] init];
                wrapper.marker = routePoint;
                [result collect:wrapper provider:self];
            }
        }
    }
}

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:OAMapMarkerWrapper.class])
    {
        OAMapMarkerWrapper *wrapper = obj;
        if (const auto routePoint = reinterpret_cast<const OsmAnd::MapMarker *>(wrapper.marker.get()))
        {
            OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
            double lat = OsmAnd::Utilities::get31LatitudeY(routePoint->getPosition().y);
            double lon = OsmAnd::Utilities::get31LongitudeX(routePoint->getPosition().x);
            targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
            
            OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
            OARTargetPoint *startPoint = [targetPointsHelper getPointToStart];
            OARTargetPoint *finishPoint = [targetPointsHelper getPointToNavigate];
            NSArray<OARTargetPoint *> *intermediates = [targetPointsHelper getIntermediatePoints];
            
            if (startPoint)
            {
                if ([OAUtilities isCoordEqual:startPoint.point.coordinate.latitude srcLon:startPoint.point.coordinate.longitude destLat:lat destLon:lon])
                {
                    targetPoint.title = [startPoint getPointDescription].name;
                    targetPoint.icon = [UIImage imageNamed:@"ic_list_startpoint"];
                    targetPoint.type = OATargetRouteStart;
                    targetPoint.targetObj = startPoint;
                }
            }
            if (!targetPoint.targetObj && finishPoint)
            {
                if ([OAUtilities isCoordEqual:finishPoint.point.coordinate.latitude srcLon:finishPoint.point.coordinate.longitude destLat:lat destLon:lon])
                {
                    targetPoint.title = [finishPoint getPointDescription].name;
                    targetPoint.icon = [UIImage imageNamed:@"ic_list_destination"];
                    targetPoint.type = OATargetRouteFinish;
                    targetPoint.targetObj = finishPoint;
                }
            }
            if (!targetPoint.targetObj)
            {
                for (OARTargetPoint *p in intermediates)
                {
                    if ([OAUtilities isCoordEqual:p.point.coordinate.latitude srcLon:p.point.coordinate.longitude destLat:lat destLon:lon])
                    {
                        targetPoint.title = [p getPointDescription].name;
                        targetPoint.icon = [UIImage imageNamed:@"list_intermediate"];
                        targetPoint.type = OATargetRouteIntermediate;
                        targetPoint.targetObj = p;
                    }
                }
            }
            
            targetPoint.sortIndex = (NSInteger)targetPoint.type;
            return targetPoint;
        }
        else
        {
            return nil;
        }
    }
    return nil;
}

- (OAPointDescription *)getObjectName:(id)o
{
    if ([o isKindOfClass:OAMapMarkerWrapper.class])
    {
        OAMapMarkerWrapper *wrapper = o;
        if (const auto routePoint = reinterpret_cast<const OsmAnd::MapMarker *>(wrapper.marker.get()))
        {
            NSString *name;
            NSString *type;
            double lat = OsmAnd::Utilities::get31LatitudeY(routePoint->getPosition().y);
            double lon = OsmAnd::Utilities::get31LongitudeX(routePoint->getPosition().x);
            
            OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
            OARTargetPoint *startPoint = [targetPointsHelper getPointToStart];
            OARTargetPoint *finishPoint = [targetPointsHelper getPointToNavigate];
            NSArray<OARTargetPoint *> *intermediates = [targetPointsHelper getIntermediatePoints];
            
            if (startPoint && [OAUtilities isCoordEqual:startPoint.point.coordinate.latitude srcLon:startPoint.point.coordinate.longitude destLat:lat destLon:lon])
            {
                name = [startPoint getPointDescription].name;
                type = OALocalizedString(@"starting_point");
            }
            else if (finishPoint && [OAUtilities isCoordEqual:finishPoint.point.coordinate.latitude srcLon:finishPoint.point.coordinate.longitude destLat:lat destLon:lon])
            {
                name = [finishPoint getPointDescription].name;
                type = OALocalizedString(@"destination_point");
            }
            else
            {
                for (int i = 0; i < intermediates.count; i ++)
                {
                    OARTargetPoint *p = intermediates[i];
                    if ([OAUtilities isCoordEqual:p.point.coordinate.latitude srcLon:p.point.coordinate.longitude destLat:lat destLon:lon])
                    {
                        name = [p getPointDescription].name;
                        type = OALocalizedString(@"destination_point", @(i+1));
                    }
                }
            }
            
            return [[OAPointDescription alloc] initWithType:POINT_TYPE_TARGET typeName:type name:name];
        }
    }
    return nil;
}

- (CLLocation *)getObjectLocation:(id)o
{
    if ([o isKindOfClass:OAMapMarkerWrapper.class])
    {
        OAMapMarkerWrapper *wrapper = o;
        if (const auto routePoint = reinterpret_cast<const OsmAnd::MapMarker *>(wrapper.marker.get()))
        {
            double lat = OsmAnd::Utilities::get31LatitudeY(routePoint->getPosition().y);
            double lon = OsmAnd::Utilities::get31LongitudeX(routePoint->getPosition().x);
            return [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        }
    }
    return nil;
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

#pragma mark - OAMoveObjectProvider

- (BOOL)isObjectMovable:(id)object
{
    return [object isKindOfClass:OARTargetPoint.class];
}

- (void)applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OARTargetPoint *point = (OARTargetPoint *)object;
        if (point.start)
        {
            [_targetPoints setStartPoint:[[CLLocation alloc] initWithLatitude:position.latitude longitude:position.longitude] updateRoute:YES name:nil];
        }
        else if (point.intermediate)
        {
            [_targetPoints removeWayPoint:YES index:point.index];
            [_targetPoints navigateToPoint:[[CLLocation alloc] initWithLatitude:position.latitude longitude:position.longitude] updateRoute:YES intermediate:point.index];
        }
        else
        {
            [_targetPoints navigateToPoint:[[CLLocation alloc] initWithLatitude:position.latitude longitude:position.longitude] updateRoute:YES intermediate:-1];
        }
    }
}

- (UIImage *)getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        OARTargetPoint *point = (OARTargetPoint *)object;
        if (point.start)
            return [UIImage imageNamed:@"map_start_point"];
        else if (point.intermediate)
            return [self getIntermediateUIImage:point.index + 1];
        else
            return [UIImage imageNamed:@"map_target_point"];
    }
    return nil;
}

- (void)setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OARTargetPoint *point = (OARTargetPoint *)object;
        
        const auto& pos = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.getLatitude, point.getLongitude));
        for (const auto& marker : _markersCollection->getMarkers())
        {
            if (pos == marker->getPosition())
            {
                marker->setIsHidden(hidden);
            }
        }
    }
}

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment
{
    return EOAPinAlignmentTop;
}


- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment
{
    return EOAPinAlignmentCenterHorizontal;
}

@end


@implementation OAMapMarkerWrapper

@end
