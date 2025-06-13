//
//  OAImpassableRoadsLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImpassableRoadsLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAAvoidSpecificRoads.h"
#import "OAStateChangedListener.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"
#import "OACompoundIconUtils.h"
#import "OAAppSettings.h"
#import "OAMapSelectionResult.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/SingleSkImage.h>
#include <binaryRead.h>

static const int START_ZOOM = 10;

@interface OAImpassableRoadsLayer () <OAStateChangedListener>

@end

@implementation OAImpassableRoadsLayer
{
    OAAvoidSpecificRoads *_avoidRoads;
    double _textSize;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _markersCollection;
}

- (NSString *) layerId
{
    return kImpassableRoadsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    _textSize = [[OAAppSettings sharedManager].textSize get];

    _avoidRoads = [OAAvoidSpecificRoads instance];
    [self updatePoints];
    [_avoidRoads addListener:self];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    [_avoidRoads removeListener:self];
}

- (BOOL)updateLayer
{
    if (![super updateLayer])
        return NO;
        
    _textSize = [[OAAppSettings sharedManager].textSize get];
    return YES;
}

- (void) resetPoints
{
    if (_markersCollection)
        [self.mapView removeKeyedSymbolsProvider:_markersCollection];
    
    _markersCollection.reset(new OsmAnd::MapMarkersCollection());
}

- (void) setupPoints
{
    NSArray<OAAvoidRoadInfo *> *roads = [_avoidRoads getImpassableRoads];
    for (OAAvoidRoadInfo *roadInfo : roads)
    {
        CLLocation *location = [_avoidRoads getLocation:roadInfo.roadId];
        if (location)
        {
            auto avoidIcon = [OACompoundIconUtils getScaledIcon:@"map_pin_avoid_road" scale:_textSize];
            if (!avoidIcon)
                return;

            const OsmAnd::LatLon latLon(location.coordinate.latitude, location.coordinate.longitude);
            std::shared_ptr<OsmAnd::MapMarker> mapMarker = OsmAnd::MapMarkerBuilder()
            .setIsAccuracyCircleSupported(false)
            .setBaseOrder(self.pointsOrder + 1)
            .setIsHidden(false)
            .setPinIcon(OsmAnd::SingleSkImage(avoidIcon))
            .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
            .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
            .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
            .buildAndAddToCollection(_markersCollection);
        }
    }
    
    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_markersCollection];
    }];
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getImpassableMarkersCollection
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
    [self updatePoints];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OAAvoidRoadInfo class]])
    {
        OAAvoidRoadInfo *roadInfo = (OAAvoidRoadInfo *)obj;
        OAAvoidSpecificRoads *avoidRoads = [OAAvoidSpecificRoads instance];
        CLLocation *location = [avoidRoads getLocation:roadInfo.roadId];
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.location = location.coordinate;
        targetPoint.title = roadInfo.name;
        targetPoint.icon = [UIImage imageNamed:@"map_pin_avoid_road"];
        targetPoint.type = OATargetImpassableRoad;
        targetPoint.targetObj = roadInfo;
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(OAMapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    NSArray<OAAvoidRoadInfo *> *impassableRoads = [[OAAvoidSpecificRoads instance] getImpassableRoads];
    
    if ([self.mapViewController getMapZoom] >= START_ZOOM && !excludeUntouchableObjects && !NSArrayIsEmpty(impassableRoads))
    {
        int radiusPixels = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
        CGPoint pixel = [result getPoint];
        CGPoint topLeft = CGPointMake(pixel.x - radiusPixels, pixel.y - (radiusPixels / 2));
        CGPoint bottomRight = CGPointMake(pixel.x + radiusPixels, pixel.y + (radiusPixels * 3));
        OsmAnd::AreaI touchPolygon31 = [OANativeUtilities getPolygon31FromScreenArea:topLeft bottomRight:bottomRight];
        if (touchPolygon31 == OsmAnd::AreaI())
            return;
        
        for (OAAvoidRoadInfo *road in impassableRoads)
        {
            CLLocation *latLon = [[OAAvoidSpecificRoads instance] getLocation:road.roadId];
            BOOL shouldAdd = [OANativeUtilities isPointInsidePolygon:latLon.coordinate.latitude lon:latLon.coordinate.longitude polygon31:touchPolygon31];
            if (shouldAdd)
                [result collect:road provider:self];
        }
    }
}

- (BOOL) isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OAAvoidRoadInfo.class])
    {
        return ((OAAvoidRoadInfo *)obj).location;
    }
    return  nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OAAvoidRoadInfo.class])
    {
        OAAvoidRoadInfo *route = obj;
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_BLOCKED_ROAD name:[route name]];
    }
    return  nil;
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

#pragma mark - OAMoveObjectProvider

- (BOOL)isObjectMovable:(id)object
{
    return [object isKindOfClass:OAAvoidRoadInfo.class];
}

- (void)applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OAAvoidRoadInfo *roadInfo = (OAAvoidRoadInfo *)object;
        [_avoidRoads removeImpassableRoad:roadInfo];
        [_avoidRoads addImpassableRoad:[[CLLocation alloc] initWithLatitude:position.latitude longitude:position.longitude] skipWritingSettings:NO appModeKey:nil];
    }
}

- (void)setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OAAvoidRoadInfo *roadInfo = (OAAvoidRoadInfo *)object;
        CLLocation *location = [_avoidRoads getLocation:OsmAnd::ObfObjectId::fromRawId(roadInfo.roadId)];
        const auto& pos = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude));
        for (const auto& marker : _markersCollection->getMarkers())
        {
            if (pos == marker->getPosition())
            {
                marker->setIsHidden(hidden);
            }
        }
    }
}

- (UIImage *)getPointIcon:(id)object
{
    return [UIImage imageNamed:@"map_pin_avoid_road"];
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
