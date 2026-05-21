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

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmEditsListViewController : OACompoundViewController

@property (nonatomic, weak) id<MyPlacesDelegate> myPlacesDelegate;

@end

NS_ASSUME_NONNULL_END
