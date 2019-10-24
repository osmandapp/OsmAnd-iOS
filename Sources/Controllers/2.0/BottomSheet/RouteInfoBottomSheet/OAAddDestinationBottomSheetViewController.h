//
//  OAAddDestinationBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAWaypointUIHelper.h"

typedef NS_ENUM(NSInteger, EOADestinationType)
{
    EOADestinationTypeStart = 0,
    EOADestinationTypeFinish,
    EOADestinationTypeIntermediate,
    EOADestinationTypeHome,
    EOADestinationTypeWork
};

@class OASwitchableAction;
@class OAAddDestinationBottomSheetViewController;

// TODO remove dialog and paste protocol here

@interface OAAddDestinationBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@interface OAAddDestinationBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) EOADestinationType type;
@property (nonatomic, weak) id<OAWaypointSelectionDelegate> delegate;

- (id) initWithType:(EOADestinationType) type;

@end

