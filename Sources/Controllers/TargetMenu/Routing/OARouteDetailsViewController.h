//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"

@class OARouteDirectionInfo;

@interface OACumulativeInfo : NSObject

@property (nonatomic) double distance;
@property (nonatomic) long time;

+ (OACumulativeInfo *) getRouteDirectionCumulativeInfo:(NSInteger)position routeDirections:(NSArray<OARouteDirectionInfo *> *)routeDirections;
+ (NSString *) getTimeDescription:(OARouteDirectionInfo *)model;

@end


@interface OARouteDetailsViewController : OARouteBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarDividerView;

@end
