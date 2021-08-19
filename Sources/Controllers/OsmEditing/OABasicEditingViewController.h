//
//  OABasicEditingViewController.h
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAOsmEditingViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OABasicEditingViewController : UITableViewController

- (instancetype)initWithFrame:(CGRect)frame;

-(void)setDataProvider:(id<OAOsmEditingDataProtocol>)provider;

@end

NS_ASSUME_NONNULL_END
