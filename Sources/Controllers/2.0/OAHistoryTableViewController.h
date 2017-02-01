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

@required

- (void)didSelectHistoryItem:(OAHistoryItem *)item;
- (void)enterHistoryEditingMode;
- (void)exitHistoryEditingMode;
- (void)historyItemsSelected:(int)count;

@end

@interface OAHistoryTableViewController : UITableViewController

@property (nonatomic) BOOL searchNearMapCenter;
@property (nonatomic, assign) OsmAnd::PointI myLocation;

@property (weak, nonatomic) id<OAHistoryTableDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)reloadData;
- (void)updateDistanceAndDirection;

- (void)deleteSelected;
- (void)editDone;

@end
