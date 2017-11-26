//
//  OAMapActions.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPointDescription, OAGPX, OATargetPoint;

@interface OAMapActions : NSObject

- (void) enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName;
- (void) enterRoutePlanningModeGivenGpx:(OAGPX *)gpxFile from:(CLLocation *)from fromName:(OAPointDescription *)fromName
         useIntermediatePointsByDefault:(BOOL)useIntermediatePointsByDefault showDialog:(BOOL)showDialog;

- (void) setFirstMapMarkerAsTarget;
- (void) stopNavigationWithoutConfirm;
- (void) stopNavigationActionConfirm;

- (void) setGPXRouteParams:(OAGPX *)result;

- (void) navigate:(OATargetPoint *)targetPoint;

@end
