//
//  OAStatisticsSelectionBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAWaypointUIHelper.h"

typedef NS_ENUM(NSInteger, EOARouteStatisticsMode)
{
    EOARouteStatisticsModeBoth = 0,
    EOARouteStatisticsModeAltitude,
    EOARouteStatisticsModeSlope
};

@class OAStatisticsSelectionBottomSheetViewController;

@protocol OAStatisticsSelectionDelegate <NSObject>

@required

- (void) onNewModeSelected:(EOARouteStatisticsMode)mode;

@end

@interface OAStatisticsSelectionBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@interface OAStatisticsSelectionBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) EOARouteStatisticsMode mode;
@property (nonatomic, weak) id<OAStatisticsSelectionDelegate> delegate;

- (id) initWithMode:(EOARouteStatisticsMode)mode;

@end

