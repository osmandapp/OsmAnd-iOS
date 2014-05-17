//
//  OATableViewCell.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCell.h"

#define _(name) OATableViewCell__##name
#define inflate _(inflate)

@implementation OATableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
}

- (UITableView*)tableView
{
    //TODO: cache value until detached!
    id view = [self superview];
    while(view != nil && ![view isKindOfClass:[UITableView class]])
        view = [view superview];

    return (UITableView*)view;
}

@end
