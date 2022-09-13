//
//  OACarPlayPurchaseViewController.h
//  OsmAnd Maps
//
//  Created by Paul on 13.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CPWindow;

@interface OACarPlayPurchaseViewController : UIViewController

- (instancetype) initWithCarPlayWindow:(CPWindow *)window viewController:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
