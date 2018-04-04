//
//  OATableView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OATableView;

@protocol OATableViewDelegate

@required
- (void) tableViewContentOffsetChanged:(OATableView *)tableView contentOffset:(CGPoint)contentOffset;
- (void) tableViewWillEndDragging:(OATableView *)tableView withVelocity:(CGPoint)velocity withStartOffset:(CGPoint)startOffset;
- (BOOL) tableViewScrollAllowed:(OATableView *)tableView;

@end

@interface OATableView : UITableView

@property (nonatomic, weak) id<OATableViewDelegate> oaDelegate;

- (BOOL) isSliding;

@end
