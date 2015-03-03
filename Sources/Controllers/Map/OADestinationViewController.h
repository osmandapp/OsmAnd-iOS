//
//  OADestinationViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OADestinationCell.h"

@class OADestination;

@protocol OADestinationViewControllerProtocol
@optional

- (void)destinationViewLayoutDidChange;
- (void)destinationViewMoveToLatitude:(double)lat lon:(double)lon;

@end

@interface OADestinationViewController : UIViewController<OADestinatioCellProtocol>

@property (nonatomic, assign) BOOL singleLineOnly;
@property (nonatomic, assign) CGFloat top;
@property (weak, nonatomic) id<OADestinationViewControllerProtocol> delegate;

- (NSArray *)allDestinations;

- (void)startLocationUpdate;
- (void)stopLocationUpdate;

- (void)updateFrame;

- (BOOL) addDestination:(OADestination *)destination;
- (void) doLocationUpdate;

@end
