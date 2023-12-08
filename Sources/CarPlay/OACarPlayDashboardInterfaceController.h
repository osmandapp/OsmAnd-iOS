//
//  OACarPlayDashboardInterfaceController.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"
#import "OACarPlayMapViewController.h"
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import <CarPlay/CarPlay.h>

@protocol OACarPlayDashboardDelegate <NSObject>

- (void) onMapControlPressed:(CPPanDirection)panDirection;
- (void) onZoomInPressed;
- (void) onZoomOutPressed;
- (void) onCenterMapPressed;
- (void) enterNavigationMode;
- (void) exitNavigationMode;
- (void) onLocationChanged;
- (void) on3DMapPressed;

- (void) centerMapOnRoute:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight;

@end

@class CPInterfaceController;

@interface OACarPlayDashboardInterfaceController : OABaseCarPlayInterfaceController <OACarPlayMapViewDelegate>

@property (nonatomic, weak) id<OACarPlayDashboardDelegate> delegate;

- (void)openSearch;
- (void)openNavigation;

@end
