//
//  OATargetInfoViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OACollapsableView.h"
#import "OARowInfo.h"

#define kCollapseDetailsRowType @"kCollapseDetailsRowType"
#define kDescriptionRowType @"kDescriptionRowType"
#define kCommentRowType @"kCommentRowType"
#define kTimestampRowType @"kTimestampRowType"
#define kGroupRowType @"kGroupRowType"

@interface OATargetInfoViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSArray<OARowInfo *> *additionalRows;

- (BOOL) needCoords;
- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) buildDescription:(NSMutableArray<OARowInfo *> *)rows;
- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) buildRowsInternal:(NSMutableArray<OARowInfo *> *)rows;
- (void) buildDateRow:(NSMutableArray<OARowInfo *> *)rows timestamp:(NSDate *)timestamp;
- (void) buildCommentRow:(NSMutableArray<OARowInfo *> *)rows comment:(NSString *)comment;
- (void) buildCoordinateRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) rebuildRows;
- (void) setRows:(NSMutableArray<OARowInfo *> *)rows;

+ (UIImage *) getIcon:(NSString *)fileName;
+ (UIImage *) getIcon:(NSString *)fileName size:(CGSize)size;

@end
