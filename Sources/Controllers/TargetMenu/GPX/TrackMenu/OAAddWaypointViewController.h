//
//  OAAddWaypointViewController.h
//  OsmAnd
//
//  Created by Skalii on 12.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OASTrackItem;

@interface OAAddWaypointViewController : OATargetMenuViewController

- (instancetype)initWithGpx:(OASTrackItem *)gpx
            targetMenuState:(OATargetMenuViewControllerState *)targetMenuState;

@end
