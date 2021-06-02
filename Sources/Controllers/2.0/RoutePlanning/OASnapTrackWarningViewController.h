//
//  OASnapTrackWarningViewController.h
//  OsmAnd
//
//  Created by Skalii on 28.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"

@protocol OASnapTrackWarningBottomSheetDelegate <NSObject>

@required

- (void)onCancelSnapApproximation;
- (void)onContinueSnapApproximation;

@end

@interface OASnapTrackWarningBottomSheetScreen : NSObject<OABottomSheetScreen>

- (instancetype) initWithTable:(UITableView *)tableView viewController:(OABottomSheetTwoButtonsViewController *)viewController param:(id)param;

@end

@interface OASnapTrackWarningViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic) id<OASnapTrackWarningBottomSheetDelegate> delegate;

- (void)setContinue:(BOOL)__continue;

@end
