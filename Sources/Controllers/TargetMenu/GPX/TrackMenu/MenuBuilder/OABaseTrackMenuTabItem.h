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

@property (nonatomic) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (NSString *)getTabTitle;
- (UIImage *)getTabIcon;
- (EOATrackMenuHudTab)getTabMode;

+ (UIImage *)getUnselectedIcon:(NSString *)iconName;

- (void)generateData;
- (void)resetData;
- (OAGPXTableData *)getTableData;
- (void)runAdditionalActions;

@end
