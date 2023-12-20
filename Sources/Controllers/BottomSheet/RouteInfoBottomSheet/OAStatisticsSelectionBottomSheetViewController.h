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

@class OAGPXTrackAnalysis;

typedef NS_ENUM(NSInteger, EOARouteStatisticsMode)
{
    EOARouteStatisticsModeAltitudeSlope = 0,
    EOARouteStatisticsModeAltitudeSpeed,
    EOARouteStatisticsModeAltitude,
    EOARouteStatisticsModeSlope,
    EOARouteStatisticsModeSpeed,

    EOARouteStatisticsModeSensorSpeed,
    EOARouteStatisticsModeSensorHearRate,
    EOARouteStatisticsModeSensorBikePower,
    EOARouteStatisticsModeSensorBikeCadence,
    EOARouteStatisticsModeSensorTemperature
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
@property (nonatomic, readonly) OAGPXTrackAnalysis *analysis;
@property (nonatomic, weak) id<OAStatisticsSelectionDelegate> delegate;

- (instancetype)initWithMode:(EOARouteStatisticsMode)mode analysis:(OAGPXTrackAnalysis *)analysis;

@end

