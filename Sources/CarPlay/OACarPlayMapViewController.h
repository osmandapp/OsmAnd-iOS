//
//  OACarPlayMapViewController.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACarPlayDashboardInterfaceController.h"

@protocol OACarPlayDashboardDelegate;

@protocol OACarPlayMapViewDelegate <NSObject>

- (void)onInterfaceControllerAttached;
- (void)onInterfaceControllerDetached;
- (void)onMapViewAttached;
- (void)onUpdateMapTemplateStyle;

@end

@class CPWindow, OAMapViewController;

@interface OACarPlayMapViewController : UIViewController <OACarPlayDashboardDelegate>

@property (nonatomic, weak) id<OACarPlayMapViewDelegate> delegate;

- (instancetype)initWithCarPlayWindow:(CPWindow *)window mapViewController:(OAMapViewController *)mapVC;

- (void)detachFromCarPlayWindow;
- (void)configureSpeedometer;

@end
