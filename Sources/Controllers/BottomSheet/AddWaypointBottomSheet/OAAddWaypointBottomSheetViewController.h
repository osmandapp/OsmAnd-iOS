//
//  OAAddWaypointBottomSheetViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"

@class OATargetPoint;

@interface OAAddWaypointBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@interface OAAddWaypointBottomSheetViewController : OABottomSheetViewController

@property (nonatomic, readonly) OATargetPoint *targetPoint;

- (instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint;

@end
