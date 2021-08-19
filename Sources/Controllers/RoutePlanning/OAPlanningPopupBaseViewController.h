//
//  OAPlanningPopupBaseViewController.h
//  OsmAnd Maps
//
//  Created by Paul on 03.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAPlanningPopupBaseViewController, OAGpxRouteApproximation, OAGpxTrkPt, OAApplicationMode, OAMeasurementEditingContext;

@protocol OAPlanningPopupDelegate <NSObject>

- (void) onPopupDismissed;

- (void) onCancelSnapApproximation:(BOOL)hasApproximationStarted;
- (void) onContinueSnapApproximation:(OAPlanningPopupBaseViewController *)approximationController;

- (void)onApplyGpxApproximation;
- (void)onGpxApproximationDone:(NSArray<OAGpxRouteApproximation *> *)gpxApproximations pointsList:(NSArray<NSArray<OAGpxTrkPt *> *> *)pointsList mode:(OAApplicationMode *)mode;

- (OAMeasurementEditingContext *) getCurrentEditingContext;

@end

@interface OAPlanningPopupBaseViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *headerViewHeightConstant;

@property (weak, nonatomic) id<OAPlanningPopupDelegate> delegate;

- (CGFloat)initialHeight;
- (void) dismiss;

- (void) setHeaderViewVisibility:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
