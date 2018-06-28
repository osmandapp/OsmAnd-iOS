//
//  OAContextMenuProvider.h
//  OsmAnd
//
//  Created by Alexey on 28/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#include <OsmAndCore/Map/IMapRenderer.h>

const static CGFloat kDefaultSearchRadiusOnMap = 20.0;

@class OATargetPoint, OAPointDescription;

@protocol OAContextMenuProvider<NSObject>

@required
- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation;
//- (CLLocationCoordinate2D) getObjectLocation(OATargetPoint *)o;
//- (OAPointDescription *) getObjectName:(OATargetPoint *)o;
//- (BOOL) disableSingleTap;
//- (BOOL) disableLongPressOnMap;
//- (BOOL) isObjectClickable:(OATargetPoint *)o;
//- (BOOL) runExclusiveAction:(OATargetPoint *)o unknownLocation:(BOOL)unknownLocation;

@end
