//
//  OATrackMenuUIBuilder.h
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATrackMenuHudViewController.h"

@class OATabBar;

@interface OATrackMenuUIBuilder : NSObject

@property (nonatomic) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (instancetype)initWithSelectedTab:(EOATrackMenuHudTab)selectedTab;

- (OAGPXTableData *)generateSectionsData;
- (OAGPXTableData *)getTableData;
- (void)updateSelectedTab:(EOATrackMenuHudTab)selectedTab;
- (void)runAdditionalActions;

- (void)setupTabBar:(OATabBar *)tabBarView
        parentWidth:(CGFloat)parentWidth;

@end
