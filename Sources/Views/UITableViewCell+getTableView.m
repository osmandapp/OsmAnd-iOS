//
//  UITableViewCell+getTableView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "UITableViewCell+getTableView.h"

@implementation UITableViewCell (getTableView)

- (UITableView*)getTableView
{
    id view = [self superview];
    while(view != nil && ![view isKindOfClass:[UITableView class]])
        view = [view superview];

    return (UITableView*)view;
}

@end
