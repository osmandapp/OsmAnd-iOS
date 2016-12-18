//
//  OAHistoryTableViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <OsmAndCore.h>

@class OAHistoryItem;

@protocol OAHistoryTableDelegate

@optional

- (void)didSelectHistoryItem:(OAHistoryItem *)item;

@end

@interface OAHistoryTableViewController : UITableViewController

@property (nonatomic) NSArray* dataArray;
@property (nonatomic) BOOL searchNearMapCenter;
@property (nonatomic, assign) OsmAnd::PointI myLocation;

@property (weak, nonatomic) id<OAHistoryTableDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateDistancesAndSort;

@end
