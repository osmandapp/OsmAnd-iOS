//
//  OARouteInfoView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OARouteInfoView : UIView<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *waypointsButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *goButton;

@property (weak, nonatomic) IBOutlet UIView *swapButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *swapButton;

+ (int) getDirectionInfo;
+ (BOOL) isVisible;

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete;
- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;

- (void) addWaypoint;

- (void) update;
- (void) updateMenu;

@end
