//
//  OARecGPXLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXRecLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATargetPoint.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxWptItem.h"
#import "OAGPXDatabase.h"
#import "OASavingTrackHelper.h"
#import "OAGPXMutableDocument.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>

@implementation OAGPXRecLayer

- (NSString *) layerId
{
    return kGpxRecLayerId;
}

#pragma mark - OAContextMenuProvider

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    // collected by parent layer
}

#pragma mark - OAMoveObjectProvider

- (BOOL)isObjectMovable:(id)object
{
    BOOL movable = NO;
    if ([object isKindOfClass:OAGpxWptItem.class])
        movable = ((OAGpxWptItem *)object).docPath == nil;
    
    return movable;
}

@end
