//
//  OATableViewCellWithSwitch.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCellWithSwitch.h"

#import "OALog.h"

#define _(name) OATableViewCellWithSwitch__##name
#define inflate _(inflate)

@implementation OATableViewCellWithSwitch

+ (NSString *) getCellIdentifier
{
    return @"OATableViewCellWithSwitch";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self inflate];
    }
    return self;
}

- (void)awakeFromNib
{
    [self inflate];
}

- (void)inflate
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

- (void)onSwitchStateChanged:(id)sender
{
    // Obtain tableview and locate self
    NSIndexPath* ownPath = [self.tableView indexPathForCell:self];
    if (self.tableView == nil || ![self.tableView.delegate conformsToProtocol:@protocol(OATableViewWithSwitchDelegate) ] || ownPath == nil)
    {
        OALog(@"Warning: lost state change");
        return;
    }

    id<OATableViewWithSwitchDelegate> tableViewDelegate = (id<OATableViewWithSwitchDelegate>)self.tableView.delegate;
    [tableViewDelegate tableView:self.tableView accessorySwitchChangedStateForRowWithIndexPath:ownPath];
}

@end
