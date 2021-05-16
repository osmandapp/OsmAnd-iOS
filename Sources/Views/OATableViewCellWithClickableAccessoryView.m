//
//  OATableViewCellWithClickableAccessoryView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCellWithClickableAccessoryView.h"

#import "OALog.h"

#define _(name) OATableViewCellWithClickableAccessoryView__##name
#define inflate _(inflate)

@implementation OATableViewCellWithClickableAccessoryView
{
    UITapGestureRecognizer* _tapGestureRecognizer;
}

+ (NSString *) getCellIdentifier
{
    return @"OATableViewCellWithClickableAccessoryView";
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style
       andCustomAccessoryView:(UIView *)customAccessoryView
              reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self inflate];
        self.accessoryView = customAccessoryView;
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
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonTapped:)];
}

- (void)setAccessoryView:(UIView *)accessoryView
{
    if (self.accessoryView != nil)
        [self.accessoryView removeGestureRecognizer:_tapGestureRecognizer];
    if (accessoryView != nil)
        [accessoryView addGestureRecognizer:_tapGestureRecognizer];

    [super setAccessoryView:accessoryView];
}

- (void)onButtonTapped:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded)
        return;

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
