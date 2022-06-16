//
//  OABaseTrackMenuTabItem.h
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATrackMenuHudViewController.h"

@class OAGPXTableSectionData;

@interface OABaseTrackMenuTabItem : NSObject

@property (nonatomic, readonly) BOOL isGeneratedData;

@property (nonatomic, weak) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (NSString *)getTabTitle;
- (UIImage *)getTabIcon;
- (EOATrackMenuHudTab)getTabMode;

+ (UIImage *)getUnselectedIcon:(NSString *)iconName;

- (void)generateData;
- (void)resetData;
- (OAGPXTableData *)getTableData;
- (void)runAdditionalActions;

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData;
- (BOOL)isOn:(OAGPXBaseTableData *)tableData;
- (void)updateData:(OAGPXBaseTableData *)tableData;
- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData;
- (void)onButtonPressed:(OAGPXBaseTableData *)tableData;

@end
