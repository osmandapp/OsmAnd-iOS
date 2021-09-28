//
//  OATrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"

@protocol OATrackMenuViewControllerDelegate <NSObject>

@optional

- (void)openAnalysis:(EOARouteStatisticsMode)modeType;
- (void)onExitAnalysis;

@end

@interface OATrackMenuHudViewController : OABaseTrackMenuHudViewController

@end
