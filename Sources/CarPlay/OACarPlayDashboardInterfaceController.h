//
//  OACarPlayDashboardInterfaceController.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayInterfaceController.h"
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import <CarPlay/CarPlay.h>

API_AVAILABLE(ios(12.0))
@protocol OACarPlayDashboardDelegate <NSObject>

- (void) onMapControlPressed:(CPPanDirection)panDirection;
- (void) onZoomInPressed;
- (void) onZoomOutPressed;
- (void) onCenterMapPressed;

- (void) centerMapOnRoute:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight;

@end

@class CPInterfaceController;

API_AVAILABLE(ios(12.0))
@interface OACarPlayDashboardInterfaceController : OABaseCarPlayInterfaceController

@property (nonatomic, weak) id<OACarPlayDashboardDelegate> delegate;

@end
