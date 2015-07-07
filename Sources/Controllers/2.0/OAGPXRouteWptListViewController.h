//
//  OAGPXRouteWptListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@class OAGPXRouteDocument;

@protocol OAGPXRouteWptListViewControllerDelegate <NSObject>

- (void)routePointsChanged;

@end

@interface OAGPXRouteWptListViewController : UITableViewController

@property (nonatomic) NSArray *allGroups;
@property (weak, nonatomic) id<OAGPXRouteWptListViewControllerDelegate> delegate;

- (void)doViewAppear;
- (void)doViewDisappear;

- (void)generateData;
- (void)resetData;

@end
