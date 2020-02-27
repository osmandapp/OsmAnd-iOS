//
//  OAContextMenuProvider.h
//  OsmAnd
//
//  Created by Alexey on 28/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#include <OsmAndCore/Map/IMapRenderer.h>

#include <OsmAndCore/Map/MapMarker.h>

const static CGFloat kDefaultSearchRadiusOnMap = 20.0;

@class OATargetPoint, OAPointDescription;

@protocol OAContextMenuProvider<NSObject>

@required
- (OATargetPoint *) getTargetPoint:(id)obj;
- (OATargetPoint *) getTargetPointCpp:(const void *)obj;

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation;
//- (CLLocationCoordinate2D) getObjectLocation(OATargetPoint *)o;
//- (OAPointDescription *) getObjectName:(OATargetPoint *)o;
//- (BOOL) disableSingleTap;
//- (BOOL) disableLongPressOnMap;
//- (BOOL) isObjectClickable:(OATargetPoint *)o;
//- (BOOL) runExclusiveAction:(OATargetPoint *)o unknownLocation:(BOOL)unknownLocation;

@end

@protocol OAMoveObjectProvider<NSObject>

@required

- (BOOL) isObjectMovable:(id) object;

- (void) applyNewObjectPosition:(id) object position:(CLLocationCoordinate2D)position;
- (void) setPointVisibility:(id) object hidden:(BOOL)hidden;
- (UIImage *) getPointIcon:(id)object;

- (OsmAnd::MapMarker::PinIconVerticalAlignment) getVerticalAlignment:(id) object;
- (OsmAnd::MapMarker::PinIconHorisontalAlignment) getHorizontalAlignment:(id) object;

@end
