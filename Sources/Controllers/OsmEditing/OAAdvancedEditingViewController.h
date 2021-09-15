//
//  OAAdvancedEditingViewController.h
//  OsmAnd
//
//  Created by Paul on 3/27/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditingViewController.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAAdvancedEditingViewController : UITableViewController

@property (nonatomic) BOOL isKeyboardHidingAllowed;

- (instancetype)initWithFrame:(CGRect)frame;

-(void)setDataProvider:(id<OAOsmEditingDataProtocol>)provider;

@end

NS_ASSUME_NONNULL_END
