//
//  OACarPlayMapDashboardViewController.h
//  OsmAnd Maps
//
//

#import <UIKit/UIKit.h>

@class OAMapViewController;

@interface OACarPlayMapDashboardViewController : UIViewController

- (instancetype)initWithCarPlayMapViewController:(OAMapViewController *)mapVC;

- (void)attachMapToWindow;
- (void)detachFromCarPlayWindow;

@end
