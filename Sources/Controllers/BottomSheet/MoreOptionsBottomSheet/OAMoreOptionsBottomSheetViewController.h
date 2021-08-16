//
//  OAMoreOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OATargetPointView.h"

@class OATargetPoint;

@interface OAMoreOptionsBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@interface OAMoreOprionsBottomSheetViewController : OABottomSheetViewController

@property (nonatomic, readonly) OATargetPoint *targetPoint;
@property (strong, nonatomic) id<OATargetPointViewDelegate> menuViewDelegate;

- (instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint targetType:(NSString *)targetType;

@end
