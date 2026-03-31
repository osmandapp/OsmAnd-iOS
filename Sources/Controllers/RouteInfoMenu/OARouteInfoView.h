//
//  OARouteInfoView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAApplicationMode;

@interface OARouteInfoView : UIView<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *sliderView;
@property (weak, nonatomic) IBOutlet UIView *appModeViewContainer;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;

+ (int) getDirectionInfo;
+ (BOOL) isVisible;
- (BOOL)isFullScreen;

- (void)show:(BOOL)animated fullScreen:(BOOL)fullScreen onComplete:(void (^)(void))onComplete;
- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;
- (void) switchStartAndFinish;

- (void) addWaypoint;

- (void)selectAppMode:(OAApplicationMode *)appMode;
- (void) update;
- (void) updateMenu;

@end
