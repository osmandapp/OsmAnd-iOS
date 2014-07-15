//
//  OADownloadsTabBarViewController.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OADownloadsRefreshButtonDelegate <NSObject>

@optional

- (void)clickedOnRefreshButton:(UIBarButtonItem *)refreshButton forTabBar:(NSUInteger)index;
- (void)onViewDidLoadAction:(UIBarButtonItem *)refreshButton forTabBar:(NSUInteger)index;

@end

@interface OADownloadsTabBarViewController : UITabBarController

@property (nonatomic) id <OADownloadsRefreshButtonDelegate> refreshBtnDelegate;

@end
