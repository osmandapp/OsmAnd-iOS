//
//  OACarPlayMapViewController.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OACarPlayDashboardInterfaceController.h"

NS_ASSUME_NONNULL_BEGIN

@class CPWindow, OAMapViewController;

API_AVAILABLE(ios(12.0))
@interface OACarPlayMapViewController : UIViewController <OACarPlayDashboardDelegate>

- (instancetype) initWithCarPlayWindow:(CPWindow *)window mapViewController:(OAMapViewController *)mapVC;

- (void) detachFromCarPlayWindow;

@end

NS_ASSUME_NONNULL_END
