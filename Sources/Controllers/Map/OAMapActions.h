//
//  OAMapActions.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPointDescription, OAGPX, OATargetPoint, OAApplicationMode, OAGPXDocument;

@interface OAMapActions : NSObject

- (void) enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName;
- (void) enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName checkDisplayedGpx:(BOOL)shouldCheck;
- (void) enterRoutePlanningModeGivenGpx:(OAGPX *)gpxFile from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;
- (void) enterRoutePlanningModeGivenGpx:(OAGPXDocument *)gpxFile path:(NSString *)path from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;

- (void) setFirstMapMarkerAsTarget;
- (void) stopNavigationWithoutConfirm;
- (void) stopNavigationActionConfirm;

- (void) setGPXRouteParams:(OAGPX *)result;
- (void) setGPXRouteParamsWithDocument:(OAGPXDocument *)doc path:(NSString *)path;

- (void) navigate:(OATargetPoint *)targetPoint;
- (OAApplicationMode *) getRouteMode;

@end
