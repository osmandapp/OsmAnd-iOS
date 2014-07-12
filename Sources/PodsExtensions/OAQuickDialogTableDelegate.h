//
//  OAQuickDialogTableDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialog.h>
#import <QuickDialogTableDelegate.h>

@interface OAQuickDialogTableDelegate : QuickDialogTableDelegate

- (id<UITableViewDelegate, UIScrollViewDelegate>)initForTableView:(QuickDialogTableView *)tableView;

@end
