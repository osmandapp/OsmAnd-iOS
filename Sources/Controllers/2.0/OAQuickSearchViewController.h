//
//  OAQuickSearchViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#include <OsmAndCore.h>

@interface OAQuickSearchViewController : OASuperViewController

@property (nonatomic, assign) BOOL searchNearMapCenter;
@property (nonatomic, assign) double distanceFromMyLocation;
@property (nonatomic, assign) OsmAnd::PointI myLocation;

- (void) resetSearch;

@end
