//
//  OASnapTrackWarningViewController.h
//  OsmAnd
//
//  Created by Skalii on 28.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@protocol OASnapTrackWarningBottomSheetDelegate <NSObject>

@required

- (void)onCancelSnapApproximation;
- (void)onContinueSnapApproximation;

@end

@interface OASnapTrackWarningViewController : OABaseBottomSheetViewController

@property (nonatomic) id<OASnapTrackWarningBottomSheetDelegate> delegate;

@end
