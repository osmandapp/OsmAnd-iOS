//
//  OATargetInfoViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAImageCardsHelper.h"

@interface OATargetInfoViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSArray<OARowInfo *> *additionalRows;

- (BOOL) needCoords;
- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows;
- (void) rebuildRows;

+ (UIImage *) getIcon:(NSString *)fileName;

@end
