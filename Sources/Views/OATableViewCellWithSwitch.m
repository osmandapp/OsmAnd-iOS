//
//  OATableViewCellWithSwitch.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCellWithSwitch.h"

#import "OALog.h"

@implementation OATableViewCellWithSwitch

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)awakeFromNib
{
    [self ctor];
}

- (void)ctor
{
    UISwitch* switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switchView addTarget:self
                   action:@selector(onSwitchStateChanged:)
         forControlEvents:UIControlEventValueChanged];
    self.accessoryView = switchView;
}

- (UISwitch*)switchView
{
    return (UISwitch*)self.accessoryView;
}

- (UITableView*)getTableView
{
    id view = [self superview];
    while(view != nil && ![view isKindOfClass:[UITableView class]])
        view = [view superview];

    return (UITableView*)view;
}

- (void)onSwitchStateChanged:(id)sender
{
    // Obtain tableview and locate self
    UITableView* tableView = [self getTableView];
    NSIndexPath* ownPath = [tableView indexPathForCell:self];
    if(tableView == nil || ![tableView.delegate conformsToProtocol:@protocol(OATableViewWithSwitchDelegate) ] || ownPath == nil)
    {
        OALog(@"Warning: lost state change");
        return;
    }

    id<OATableViewWithSwitchDelegate> tableViewDelegate = (id<OATableViewWithSwitchDelegate>)tableView.delegate;
    [tableViewDelegate tableView:tableView accessorySwitchChangedStateForRowWithIndexPath:ownPath];
}

@end
