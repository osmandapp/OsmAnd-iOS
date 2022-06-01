//
//  OAActionConfigurationViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OAQuickActionListDelegate

- (void)updateData;

@end

@class OAQuickAction;

@interface OAActionConfigurationViewController : OACompoundViewController

-(instancetype) initWithAction:(OAQuickAction *)action isNew:(BOOL)isNew;

@property (nonatomic, weak) id<OAQuickActionListDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
