//
//  OAQuickDialogTableDelegate.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAQuickDialogTableDelegate.h"

//HACK: Undocumented value
#define UITableViewCellEditingStyleMultiSelect (UITableViewCellEditingStyle)3

@implementation OAQuickDialogTableDelegate
{
    QuickDialogTableView* __weak _tableView;
}

- (id<UITableViewDelegate, UIScrollViewDelegate>)initForTableView:(QuickDialogTableView *)tableView
{
    self = [super initForTableView:tableView];
    if (self) {
        _tableView = tableView;
    }
    return self;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != _tableView)
        return [super tableView:tableView editingStyleForRowAtIndexPath:indexPath];

    QSection *section = [_tableView.root getVisibleSectionForIndex:indexPath.section];
    return section.canDeleteRows ? UITableViewCellEditingStyleMultiSelect : UITableViewCellEditingStyleNone;
}

@end
