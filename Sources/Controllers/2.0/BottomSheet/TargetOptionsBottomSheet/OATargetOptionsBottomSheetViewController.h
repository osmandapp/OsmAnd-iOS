//
//  OATargetOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"

@interface OATargetOptionsBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@protocol OATargetOptionsDelegate <NSObject>

@required
- (void) targetOptionsUpdateControls:(BOOL)calculatingRoute;

@end

@interface OATargetOptionsBottomSheetViewController : OABottomSheetViewController

@property (nonatomic, readonly) id<OATargetOptionsDelegate> targetOptionsDelegate;

- (instancetype) initWithDelegate:(id<OATargetOptionsDelegate>)targetOptionsDelegate;

@end

