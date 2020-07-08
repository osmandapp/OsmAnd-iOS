//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OAAvoidRoadInfo;

@interface OAImpassableRoadViewController : OATargetInfoViewController

@property (nonatomic, readonly) OAAvoidRoadInfo *roadInfo;

- (instancetype) initWithRoadInfo:(OAAvoidRoadInfo *)roadInfo;

@end
