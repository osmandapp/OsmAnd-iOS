//
//  OAPlanningOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"
#import "OAClearPointsCommand.h"
#import "OAInfoBottomView.h"

@class OAApplicationMode;

@protocol OAPlanningOptionsDelegate <NSObject>

- (void) snapToRoadOptionSelected;
- (void) addNewSegmentSelected;
- (void) saveChangesSelected;
- (void) saveAsNewTrackSelected;
- (void) addToTrackSelected;
- (void) directionsSelected;
- (void) reverseRouteSelected;
- (void) clearAllSelected;

@end

@interface OAPlanningOptionsBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic) id<OAPlanningOptionsDelegate> delegate;

- (instancetype) initWithRouteAppModeKey:(NSString *)routeAppModeKey trackSnappedToRoad:(BOOL)trackSnappedToRoad addNewSegmentAllowed:(BOOL)addNewSegmentAllowed;

@end
