//
//  OAOsmEditsListViewController.h
//  OsmAnd
//
//  Created by Paul on 4/17/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACompoundViewController.h"

@protocol MyPlacesDelegate;

#define kOSMEditsTabIndex 2

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmEditsListViewController : UITableViewController

@property (nonatomic, weak) id<MyPlacesDelegate> myPlacesDelegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (void) setShouldPopToParent:(BOOL)shouldPop;

@end

NS_ASSUME_NONNULL_END
