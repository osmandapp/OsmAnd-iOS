//
//  OATableViewCellWithButton.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCellWithButton.h"

#include "OALog.h"

@implementation OATableViewCellWithButton

- (id)initWithStyle:(UITableViewCellStyle)style
      andButtonType:(UIButtonType)buttonType
    reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self ctorWithButtonType:buttonType];
    }
    return self;
}

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
    [self ctorWithButtonType:UIButtonTypeRoundedRect];
}

- (void)ctorWithButtonType:(UIButtonType)buttonType
{
    UIButton* button = [UIButton buttonWithType:buttonType];
    button.frame = CGRectZero;
    [button addTarget:self
               action:@selector(onButtonTapped:event:)
     forControlEvents:UIControlEventTouchUpInside];
    self.accessoryView = button;
}

- (UIButton*)buttonView
{
   return (UIButton*)self.accessoryView;
}

- (UITableView*)getTableView
{
    id view = [self superview];
    while(view != nil && ![view isKindOfClass:[UITableView class]])
        view = [view superview];

    return (UITableView*)view;
}

- (void)onButtonTapped:(id)sender event:(id)event
{
    // Obtain tableview and locate self
    UITableView* tableView = [self getTableView];
    NSIndexPath* ownPath = [tableView indexPathForCell:self];
    if (tableView == nil || ownPath == nil)
    {
        OALog(@"Warning: lost button tap");
        return;
    }

    if ([tableView.delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
        [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:ownPath];
}

@end
