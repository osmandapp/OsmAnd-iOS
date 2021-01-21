//
//  OAExitRoutePlanningBottomSheetViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 19.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@protocol OAExitRoutePlanningDelegate <NSObject>

- (void) onExitRoutePlanningPressed;
- (void) onSaveResultPressed;

@end

@interface OAExitRoutePlanningBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic, weak) id<OAExitRoutePlanningDelegate> delegate;

@end
