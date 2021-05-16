//
//  OATableViewCellWithButton.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCellWithButton.h"

#include "OALog.h"

#define _(name) OATableViewCellWithButton__##name
#define inflate _(inflate)
#define inflateWithButtonType _(inflateWithButtonType)

@implementation OATableViewCellWithButton

+ (NSString *) getCellIdentifier
{
    return @"OATableViewCellWithButton";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
      andButtonType:(UIButtonType)buttonType
    reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self inflateWithButtonType:buttonType];
    }
    return self;
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
    [self inflateWithButtonType:UIButtonTypeRoundedRect];
}

- (void)inflateWithButtonType:(UIButtonType)buttonType
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

- (void)onButtonTapped:(id)sender event:(id)event
{
    // Obtain tableview and locate self
    NSIndexPath* ownPath = [self.tableView indexPathForCell:self];
    if (self.tableView == nil || ownPath == nil)
    {
        OALog(@"Warning: lost button tap");
        return;
    }

    if ([self.tableView.delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
        [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:ownPath];
}

@end
