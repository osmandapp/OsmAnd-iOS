//
//  OATrackMenuViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"

@class OAGPX;
@class OATabBar;

@protocol OATrackMenuViewControllerDelegate <NSObject>

@optional

- (void)openAnalysis:(EOARouteStatisticsMode)modeType;
- (void)onExitAnalysis;

@end

@interface OATrackMenuViewController : OABaseScrollableHudViewController

- (instancetype)initWithGpx:(OAGPX *)gpx;

@end
