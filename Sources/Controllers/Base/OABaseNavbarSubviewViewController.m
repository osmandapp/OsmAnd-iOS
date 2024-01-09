//
//  OABaseNavbarSubviewViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 10.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseNavbarSubviewViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import <Foundation/Foundation.h>
#import "GeneratedAssetSymbols.h"

@implementation OABaseNavbarSubviewViewController
{
    CGFloat _subviewHeight;
    CGFloat _containerHeight;
    NSLayoutConstraint *_containerHeightConstraint;
    NSLayoutConstraint *_subviewHeightConstraint;
    UIView *_containerView;
    UIView *_separatorView;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _subviewHeight = 30;
        _containerHeight = _subviewHeight + 16;
    }
    return self;
}

- (void)updateNavbar
{
    [super updateNavbar];
    [self setupSubview];
}

- (void)setupSubview
{
    [self updateSubview:NO];
}

- (void)setupContainerAppearance:(UIView *)container
{
    switch ([self getNavbarColorScheme])
    {
        case EOABaseNavbarColorSchemeGray:
            container.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];
            break;
        case EOABaseNavbarColorSchemeOrange:
            container.backgroundColor = [[UIColor colorNamed:ACColorNameNavBarBgColorPrimary] colorWithAlphaComponent:1.0];
            break;
        case EOABaseNavbarColorSchemeWhite:
            container.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            break;
        default:
            container.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            break;
    }
}

- (UIView *)createSubview
{
    return nil;
}

- (BOOL)isNavbarBlurring
{
    return NO;
}

- (BOOL)isNavbarSeparatorVisible
{
    return _subviewHeight == 0;
}

- (CGFloat)getNavbarHeight
{
    return [self getOriginalNavbarHeight] + (_containerView != nil ? _containerHeight : 0);
}

- (CGFloat)getOriginalNavbarHeight
{
    return [super getNavbarHeight];
}

- (UIView *)getContainerView
{
    return _containerView;
}

- (void)onRotation
{
    [self updateSubview:YES];
}

- (void)updateSubviewHeight:(CGFloat)height
{
    BOOL needToUpdateAppearance = (_subviewHeight == 0 && height > 0) || (_subviewHeight > 0 && height == 0);
    _subviewHeight = height;
    _containerHeight = height;
    if (height > 0)
        _containerHeight += 16;
    _subviewHeightConstraint.constant = _subviewHeight;
    _containerHeightConstraint.constant = _containerHeight;
    if (needToUpdateAppearance)
        [self updateAppearance];
}

- (void)updateSubview:(BOOL)forceUpdate
{
    UIView *subview = [self createSubview];
    if (subview && (_containerView == nil || forceUpdate))
    {
        if (forceUpdate && _containerView != nil)
        {
            [_containerView removeFromSuperview];
            _containerView = nil;
        }
        UIView *containerView = [[UIView alloc] init];
        [self setupContainerAppearance:containerView];
        containerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:containerView];
        _containerHeightConstraint = [containerView.heightAnchor constraintEqualToConstant:_containerHeight];
        _subviewHeightConstraint = [subview.heightAnchor constraintEqualToConstant:_subviewHeight];

        [NSLayoutConstraint activateConstraints:@[
            [containerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:0],
            [containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:0],
            [containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:0],
            _containerHeightConstraint,
        ]];

        subview.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:subview];
        [NSLayoutConstraint activateConstraints:@[
            [subview.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:8],
            [subview.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-8],
            [subview.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:[OAUtilities getLeftMargin] + 20],
            [subview.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-[OAUtilities getLeftMargin] - 20],
            _subviewHeightConstraint,
        ]];

        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorNamed:ACColorNameCustomSeparator];
        _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:_separatorView];
        [NSLayoutConstraint activateConstraints:@[
            [_separatorView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
            [_separatorView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
            [_separatorView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
            [_separatorView.heightAnchor constraintEqualToConstant:0.5],
        ]];

        UIEdgeInsets contentInset = UIEdgeInsetsMake(_containerHeight, 0, 0, 0);
        self.tableView.contentInset = contentInset;
        _containerView = containerView;

        CGFloat scrollOffset = -[self getNavbarHeight];
        if (self.tableView.contentOffset.y == scrollOffset + _containerHeight)
            [self.tableView setContentOffset:CGPointMake(0, scrollOffset) animated:YES];
    }
    else if (!subview && _containerView != nil)
    {
        self.tableView.contentInset = UIEdgeInsetsMake(0., 0., 0., 0.);
        [_containerView removeFromSuperview];
        _containerView = nil;
    }
}

@end
