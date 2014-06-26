//
//  OADownloadsTabBarController.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 6/15/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "RDVTabBarController.h"

@protocol OADownloadsRefreshButtonDelegate <NSObject>

- (void)clickedOnRefreshButton:(UIBarButtonItem *)refreshButton forTabBar:(NSUInteger)index;
- (void)onViewDidLoadAction:(UIBarButtonItem *)refreshButton forTabBar:(NSUInteger)index;

@end

@interface OADownloadsTabBarController : RDVTabBarController

@property (nonatomic) id <OADownloadsRefreshButtonDelegate> refreshBtnDelegate;

@end
