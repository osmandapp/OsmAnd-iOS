//
//  OAOsmEditsListViewController.h
//  OsmAnd
//
//  Created by Paul on 4/17/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmEditsListViewController : OACompoundViewController

- (void) setShouldPopToParent:(BOOL)shouldPop;

@end

NS_ASSUME_NONNULL_END
