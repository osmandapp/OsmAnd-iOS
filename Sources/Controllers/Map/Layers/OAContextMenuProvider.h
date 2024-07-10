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

@class OATargetPoint;

typedef NS_ENUM(NSInteger, EOAPinVerticalAlignment)
{
    EOAPinAlignmentTop = 0,
    EOAPinAlignmentCenterVertical,
    EOAPinAlignmentBottom
};

typedef NS_ENUM(NSInteger, EOAPinHorizontalAlignment)
{
    EOAPinAlignmentLeft = 0,
    EOAPinAlignmentCenterHorizontal,
    EOAPinAlignmentRight
};

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

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment;
- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment;

@end
