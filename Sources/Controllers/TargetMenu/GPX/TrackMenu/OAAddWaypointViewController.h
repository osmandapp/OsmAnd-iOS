//
//  OAAddWaypointViewController.h
//  OsmAnd
//
//  Created by Skalii on 12.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OAGPX;

@interface OAAddWaypointViewController : OATargetMenuViewController

- (instancetype)initWithGpx:(OAGPX *)gpx
            targetMenuState:(OATargetMenuViewControllerState *)targetMenuState;

@end
