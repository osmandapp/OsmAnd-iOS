//
//  OATargetHistoryItemViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@class OAHistoryItem;

@interface OATargetHistoryItemViewController : OATargetInfoViewController

@property (nonatomic, readonly) OAHistoryItem *historyItem;

- (id) initWithHistoryItem:(OAHistoryItem *)historyItem;

@end
