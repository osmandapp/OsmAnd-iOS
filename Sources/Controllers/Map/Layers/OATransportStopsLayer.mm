//
//  OATransportStopsLayer.m
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportStopsLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OATargetPoint.h"
#import "OATransportStop.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@implementation OATransportStopsLayer

- (NSString *) layerId
{
    return kTransportLayerId;
}

- (void) initLayer
{
    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _markersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    [self.mapView addKeyedSymbolsProvider:_linesCollection];
    [self.mapView addKeyedSymbolsProvider:_markersCollection];
}

- (void) resetLayer
{
    [self.mapView removeKeyedSymbolsProvider:_markersCollection];
    [self.mapView removeKeyedSymbolsProvider:_linesCollection];
    
    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _markersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();    
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OATransportStop class]])
    {
        OATransportStop *item = (OATransportStop *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetTransportStop;
        targetPoint.location = item.location;        
        targetPoint.targetObj = item;
        targetPoint.title = item.name;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
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
    // TODO
}

@end
