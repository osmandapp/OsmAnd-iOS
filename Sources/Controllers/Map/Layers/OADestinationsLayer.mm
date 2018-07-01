//
//  OADestinationsLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADestinationsLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAUtilities.h"
#import "OADestination.h"
#import "OAAutoObserverProxy.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OAStateChangedListener.h"
#import "OATargetPoint.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@interface OADestinationsLayer () <OAStateChangedListener>

@end

@implementation OADestinationsLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _destinationsMarkersCollection;

    OAAutoObserverProxy* _destinationAddObserver;
    OAAutoObserverProxy* _destinationRemoveObserver;
    OAAutoObserverProxy* _destinationShowObserver;
    OAAutoObserverProxy* _destinationHideObserver;
    
    OATargetPointsHelper *_targetPoints;
}

- (NSString *) layerId
{
    return kDestinationsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _destinationAddObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationAdded:withKey:)
                                                            andObserve:self.app.data.destinationAddObservable];

    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemoved:withKey:)
                                                            andObserve:self.app.data.destinationRemoveObservable];

    _destinationShowObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationShow:withKey:)
                                                          andObserve:self.app.data.destinationShowObservable];
    _destinationHideObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationHide:withKey:)
                                                          andObserve:self.app.data.destinationHideObservable];

    [self refreshDestinationsMarkersCollection];
    
    [self.app.data.mapLayersConfiguration setLayer:self.layerId Visibility:YES];
    
    _targetPoints = [OATargetPointsHelper sharedInstance];
    [_targetPoints addListener:self];
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    [_targetPoints removeListener:self];

    if (_destinationShowObserver)
    {
        [_destinationShowObserver detach];
        _destinationShowObserver = nil;
    }
    if (_destinationHideObserver)
    {
        [_destinationHideObserver detach];
        _destinationHideObserver = nil;
    }
    if (_destinationAddObserver)
    {
        [_destinationAddObserver detach];
        _destinationAddObserver = nil;
    }
    if (_destinationRemoveObserver)
    {
        [_destinationRemoveObserver detach];
        _destinationRemoveObserver = nil;
    }
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getDestinationsMarkersCollection
{
    return _destinationsMarkersCollection;
}

- (void) refreshDestinationsMarkersCollection
{
    _destinationsMarkersCollection.reset(new OsmAnd::MapMarkersCollection());

    for (OADestination *destination in self.app.data.destinations)
        if (!destination.routePoint && !destination.hidden)
            [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude];

}

- (void) addDestinationPin:(NSString *)markerResourceName color:(UIColor *)color latitude:(double)latitude longitude:(double)longitude
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    OsmAnd::FColorRGB col(r, g, b);
    
    const OsmAnd::LatLon latLon(latitude, longitude);
    
    OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(self.baseOrder)
    .setIsHidden(false)
    .setPinIcon([OANativeUtilities skBitmapFromPngResource:markerResourceName])
    .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .setAccuracyCircleBaseColor(col)
    .buildAndAddToCollection(_destinationsMarkersCollection);
}

- (void) removeDestinationPin:(double)latitude longitude:(double)longitude;
{
    for (const auto &marker : _destinationsMarkersCollection->getMarkers())
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
        if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:latitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:longitude])
        {
            _destinationsMarkersCollection->removeMarker(marker);
            break;
        }
    }
}


- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_destinationsMarkersCollection];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_destinationsMarkersCollection];
    }];
}

- (void) onDestinationAdded:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude];
    });
}

- (void) onDestinationRemoved:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeDestinationPin:destination.latitude longitude:destination.longitude];
    });
}


- (void) onDestinationShow:(id)observer withKey:(id)key
{
    OADestination *destination = key;
    
    if (destination)
    {
        BOOL exists = NO;
        for (const auto &marker : _destinationsMarkersCollection->getMarkers())
        {
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:destination.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:destination.longitude])
            {
                exists = YES;
                break;
            }
        }
        
        if (!exists)
            [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude];
    }
}

- (void) onDestinationHide:(id)observer withKey:(id)key
{
    OADestination *destination = key;
    
    if (destination)
    {
        for (const auto &marker : _destinationsMarkersCollection->getMarkers())
        {
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:destination.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:destination.longitude])
            {
                _destinationsMarkersCollection->removeMarker(marker);
                break;
            }
        }
    }
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    [self.mapViewController runWithRenderSync:^{

        auto markers = _destinationsMarkersCollection->getMarkers();
        NSArray<OARTargetPoint *> *targets = [_targetPoints getAllPoints];
        for (auto marker : markers)
        {
            auto latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            bool hide = false;
            for (OARTargetPoint *target in targets)
            {
                if ([OAUtilities isCoordEqual:latLon.latitude srcLon:latLon.longitude destLat:target.point.coordinate.latitude destLon:target.point.coordinate.longitude])
                {
                    hide = true;
                    break;
                }
            }
            if (hide && !marker->isHidden())
                marker->setIsHidden(true);
            if (!hide && marker->isHidden())
                marker->setIsHidden(false);
        }
    }];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OADestination class]])
    {
        OADestination *destination = (OADestination *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.location = CLLocationCoordinate2DMake(destination.latitude, destination.longitude);
        targetPoint.title = destination.desc;
        targetPoint.icon = [UIImage imageNamed:destination.markerResourceName];
        
        if (destination.parking)
            targetPoint.type = OATargetParking;
        else
            targetPoint.type = OATargetDestination;
        
        targetPoint.targetObj = destination;
        
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    if (const auto markerGroup = dynamic_cast<OsmAnd::MapMarker::SymbolsGroup*>(symbolInfo->mapSymbol->groupPtr))
    {
        for (const auto& dest : _destinationsMarkersCollection->getMarkers())
        {
            if (markerGroup->getMapMarker() == dest.get())
            {
                double lat = OsmAnd::Utilities::get31LatitudeY(dest->getPosition().y);
                double lon = OsmAnd::Utilities::get31LongitudeX(dest->getPosition().x);
                
                for (OADestination *destination in self.app.data.destinations)
                {
                    if ([OAUtilities isCoordEqual:destination.latitude srcLon:destination.longitude destLat:lat destLon:lon] && !destination.routePoint)
                    {
                        OATargetPoint *targetPoint = [self getTargetPoint:destination];                        
                        if (![found containsObject:targetPoint])
                            [found addObject:targetPoint];
                    }
                }
            }
        }
    }
}

@end
