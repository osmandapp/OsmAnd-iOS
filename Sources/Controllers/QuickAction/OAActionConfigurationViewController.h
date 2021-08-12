//
//  OAActionConfigurationViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAQuickAction;

@interface OAActionConfigurationViewController : OACompoundViewController

-(instancetype) initWithAction:(OAQuickAction *)action isNew:(BOOL)isNew;

@end

NS_ASSUME_NONNULL_END
