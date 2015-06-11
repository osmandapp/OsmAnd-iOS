//
//  OAPOISearchViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#include <OsmAndCore.h>

@interface OAPOISearchViewController : OASuperViewController

@property (nonatomic, assign) BOOL searchNearMapCenter;
@property (nonatomic, assign) double distanceFromMyLocation;
@property (nonatomic, assign) OsmAnd::PointI myLocation;

@end
