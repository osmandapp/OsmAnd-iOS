//
//  OAGpxApproximationViewController.h
//  OsmAnd
//
//  Created by Skalii on 31.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAGPXDocument.h"

@protocol OAGpxApproximationBottomSheetDelegate <NSObject>

@required

- (void)onCancelGpxApproximation;
- (void)onApplyGpxApproximation;

@end

@interface OAGpxApproximationBottomSheetScreen : NSObject<OABottomSheetScreen>

- (instancetype)initWithTable:(UITableView *)tableView viewController:(OABottomSheetTwoButtonsViewController *)viewController param:(id)param;

@end

@interface OAGpxApproximationViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic) id<OAGpxApproximationBottomSheetDelegate> delegate;

- (instancetype)initWithMode:(OAApplicationMode *)mode routePoints:(NSArray<NSArray<OAGpxRtePt *> *> *)routePoints;

- (void)setApply:(BOOL)apply;

@end
