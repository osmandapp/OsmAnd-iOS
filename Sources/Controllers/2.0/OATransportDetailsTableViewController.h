//
//  OATransportDetailsTableViewController.h
//  OsmAnd
//
//  Created by Paul on 20.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol OATransportDetailsControllerDelegate

@required

- (void) onContentHeightChanged;
- (void) onDetailsRequested;
- (void) onStartPressed;
- (void) showSegmentOnMap:(NSArray<CLLocation *> *)locations;

@end

@interface OATransportDetailsTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) id<OATransportDetailsControllerDelegate> delegate;

- (instancetype)initWithRouteIndex:(NSInteger) routeIndex;

- (CGFloat) getMinimizedContentHeight;

@end
