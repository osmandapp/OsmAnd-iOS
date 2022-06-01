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

@property (nonatomic, weak) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (instancetype)initWithSelectedTab:(EOATrackMenuHudTab)selectedTab;

- (OAGPXTableData *)generateSectionsData;
- (void)resetDataInTab:(EOATrackMenuHudTab)selectedTab;
- (OAGPXTableData *)getTableData;
- (void)updateSelectedTab:(EOATrackMenuHudTab)selectedTab;
- (void)runAdditionalActions;

- (void)setupTabBar:(OATabBar *)tabBarView
        parentWidth:(CGFloat)parentWidth;

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData;
- (BOOL)isOn:(OAGPXBaseTableData *)tableData;
- (void)updateData:(OAGPXBaseTableData *)tableData;
- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData;
- (void)onButtonPressed:(OAGPXBaseTableData *)tableData;

@end
