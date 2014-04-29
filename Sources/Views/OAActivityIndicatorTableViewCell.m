//
//  OAActivityIndicatorTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAActivityIndicatorTableViewCell.h"

@implementation OAActivityIndicatorTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier
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
    UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.hidesWhenStopped = NO;
    [activityIndicatorView setColor:[UIColor grayColor]];
    activityIndicatorView.autoresizingMask = UIViewAutoresizingNone;
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.contentView addSubview:activityIndicatorView];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                 attribute:NSLayoutAttributeCenterX
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1.0f
                                                                  constant:0.0f]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.0f
                                                                  constant:0.0f]];
    //[self.contentView setNeedsUpdateConstraints];
    //[activityIndicatorView setNeedsUpdateConstraints];
    [self.contentView updateConstraintsIfNeeded];
    //[activityIndicatorView updateConstraintsIfNeeded];
}

- (UIActivityIndicatorView*)activityIndicatorView
{
    return (UIActivityIndicatorView*)[self.contentView.subviews firstObject];
}

@end
