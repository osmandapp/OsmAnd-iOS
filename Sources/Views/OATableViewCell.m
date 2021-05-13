//
//  OATableViewCell.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCell.h"

@implementation OATableViewCell
{
    UITableView* __weak _tableView;
}

+ (NSString *) getCellIdentifier
{
    return @"OATableViewCell";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    @synchronized(self)
    {
        _tableView = nil;
    }

    [super willMoveToSuperview:newSuperview];
}

- (UITableView*)tableView
{
    @synchronized(self)
    {
        if (_tableView == nil)
        {
            id view = [self superview];
            while(view != nil && !([view isKindOfClass:[UITableView class]] || [[view class] isSubclassOfClass:[UITableView class]]))
                view = [view superview];
            _tableView = (UITableView*)view;
        }

        return _tableView;
    }
}

@end
