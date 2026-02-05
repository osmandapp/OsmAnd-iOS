//
//  OAContextMenuProvider.h
//  OsmAnd
//
//  Created by Alexey on 28/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

const static CGFloat kDefaultSearchRadiusOnMap = 20.0;

@class OATargetPoint, OAPointDescription, MapSelectionResult, SelectedMapObject;

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

- (BOOL)isSecondaryProvider;

- (CLLocation *) getObjectLocation:(id)obj;
- (OAPointDescription *) getObjectName:(id)obj;

- (BOOL) showMenuAction:(id)object;
- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation;
- (int64_t) getSelectionPointOrder:(id)selectedObject;

@optional
- (void) collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects;

- (void)contextMenuDidShow:(id)targetObj;
- (void)contextMenuDidHide;

//- (BOOL) disableSingleTap;
//- (BOOL) disableLongPressOnMap;
//- (BOOL) isObjectClickable:(OATargetPoint *)o;

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
