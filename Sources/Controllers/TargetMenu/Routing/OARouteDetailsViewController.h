//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"

@class OARouteDirectionInfo, OAIntermediatePointInfo, OARTargetPoint;

@interface OACumulativeInfo : NSObject

@property (nonatomic) double distance;
@property (nonatomic) long time;

+ (OACumulativeInfo *) getRouteDirectionCumulativeInfo:(NSInteger)position routeDirections:(NSArray<OARouteDirectionInfo *> *)routeDirections;
+ (NSString *) getTimeDescription:(OARouteDirectionInfo *)model;

@end

@interface OARouteDirectionItem : NSObject

@property (nonatomic, readonly) OARouteDirectionInfo *direction;
@property (nonatomic, readonly) NSInteger directionIndex;
@property (nonatomic, readonly) OAIntermediatePointInfo *intermediatePointInfo;
@property (nonatomic, readonly) OARTargetPoint *targetPoint;
@property (nonatomic, readonly) NSInteger intermediateIndex;

- (BOOL) isIntermediate;

+ (NSArray<OARouteDirectionItem *> *) buildRouteDirectionItems:(NSArray<OARouteDirectionInfo *> *)routeDirections
                                        intermediatePointInfos:(NSArray<OAIntermediatePointInfo *> *)intermediatePointInfos
                                            intermediatePoints:(NSArray<OARTargetPoint *> *)intermediatePoints;

@end


@interface OARouteDetailsViewController : OARouteBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarDividerView;

@end
