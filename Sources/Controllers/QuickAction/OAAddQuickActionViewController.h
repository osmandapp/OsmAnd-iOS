//
//  OAAddQuickActionViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAActionConfigurationViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAAddQuickActionViewController : OACompoundViewController

@property (nonatomic, weak) id<OAQuickActionListDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
