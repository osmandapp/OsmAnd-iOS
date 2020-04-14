//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@interface OATrsansportRouteDetailsViewController : OATargetMenuViewController

@property (weak, nonatomic) IBOutlet UILabel *navBarTitleView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIView *pageControlContainer;

- (instancetype) initWithRouteIndex:(NSInteger)routeIndex;

@end
