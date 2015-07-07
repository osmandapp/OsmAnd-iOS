//
//  OAGPXRouteViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

typedef enum
{
    kSegmentRoute = 0,
    kSegmentRouteWaypoints
    
} OAGpxRouteSegmentType;


@interface OAGPXRouteViewController : OATargetMenuViewController

@property (weak, nonatomic) IBOutlet UIView *segmentViewContainer;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentView;


@end
