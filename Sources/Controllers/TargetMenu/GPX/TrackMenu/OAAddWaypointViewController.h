//
//  OAAddWaypointViewController.h
//  OsmAnd
//
//  Created by Skalii on 12.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OASGpxDataItem;

@interface OAAddWaypointViewController : OATargetMenuViewController

- (instancetype)initWithGpx:(OASGpxDataItem *)gpx
            targetMenuState:(OATargetMenuViewControllerState *)targetMenuState;

@end
