//
//  OASegmentOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"
#import "OAClearPointsCommand.h"
#import "OAInfoBottomView.h"

@class OAApplicationMode;

typedef NS_ENUM(NSInteger, EOARouteBetweenPointsDialogType)
{
    EOADialogTypeWholeRouteCalculation = 0,
    EOADialogTypeNextRouteCalculation,
    EOADialogTypePrevRouteCalculation
};

typedef NS_ENUM(NSInteger, EOARouteBetweenPointsDialogMode)
{
    EOARouteBetweenPointsDialogModeSingle = 0,
    EOARouteBetweenPointsDialogModeAll
};

@protocol OASegmentOptionsDelegate <NSObject>

- (void) onApplicationModeChanged:(OAApplicationMode *)mode dialogType:(EOARouteBetweenPointsDialogType)dialogType dialogMode:(EOARouteBetweenPointsDialogMode)dialogMode;

@end

@interface OASegmentOptionsBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic) id<OASegmentOptionsDelegate> delegate;

- (instancetype) initWithType:(EOARouteBetweenPointsDialogType)dialogType dialogMode:(EOARouteBetweenPointsDialogMode)dialogMode appMode:(OAApplicationMode *)appMode;

@end
