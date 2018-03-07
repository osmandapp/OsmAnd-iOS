//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@interface OAImpassableRoadViewController : OATargetInfoViewController

@property (nonatomic, readonly) unsigned long long roadId;

- (instancetype) initWithRoadId:(unsigned long long)roadId;

@end
