//
//  OAContextMenuLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#include <OsmAndCore/Map/MapMarker.h>

@class OATargetPoint, OAMapObject, OARenderedObject;

@protocol OAChangePositionModeDelegate <NSObject>

- (void) onMapMoved;

@end

@interface OAContextMenuLayer : OASymbolMapLayer

@property (nonatomic) id<OAChangePositionModeDelegate> changePositionDelegate;

- (void) enterChangePositionMode:(id)targetObject;
- (void) exitChangePositionMode:(id)targetObject applyNewPosition:(BOOL)applyNewPosition;
- (BOOL) isObjectMovable:(id)object;

- (std::shared_ptr<OsmAnd::MapMarker>) getContextPinMarker;

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated;
- (void) hideContextPinMarker;

- (void) showContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation forceHide:(BOOL)forceHide;

- (OATargetPoint *) getUnknownTargetPoint:(double)latitude longitude:(double)longitude;

- (OATargetPoint *) getTargetPoint:(id)obj;
- (OATargetPoint *) getTargetPointCpp:(const void *)obj;

- (void) highlightPolygon:(QVector<OsmAnd::PointI>)points;
- (void) hideRegionHighlight;

- (NSArray<OARenderedObject *> *) retrievePolygonsAroundMapObject:(double)lat lon:(double)lon mapObject:(OAMapObject *)mapObject;

@end
