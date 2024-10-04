//
//  OAMapActions.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPointDescription, OATargetPoint, OAApplicationMode;
@class OASGpxFile, OASGpxDataItem;

@interface OAMapActions : NSObject

- (void)enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName;
- (void)enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName checkDisplayedGpx:(BOOL)shouldCheck;
- (void)enterRoutePlanningModeGivenGpx:(OASGpxDataItem *)gpxFile useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;
- (void)enterRoutePlanningModeGivenGpx:(OASGpxDataItem *)gpxFile from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;
- (void)enterRoutePlanningModeGivenGpx:(OASGpxFile *)gpxFile path:(NSString *)path from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;
- (void)enterRoutePlanningModeGivenGpx:(OASGpxFile *)gpxFile appMode:(OAApplicationMode *)appMode path:(NSString *)path from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;

- (void)setFirstMapMarkerAsTarget;
- (void)stopNavigationWithoutConfirm;
- (void)stopNavigationActionConfirm;

- (void)setGPXRouteParams:(OASGpxDataItem *)result;
- (void)setGPXRouteParamsWithDocument:(OASGpxFile *)doc path:(NSString *)path;

- (void)navigate:(OATargetPoint *)targetPoint;
- (OAApplicationMode *)getRouteMode;

@end
