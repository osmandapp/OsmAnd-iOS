//
//  OACarPlayPurchaseViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 13.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACarPlayPurchaseViewController.h"
#import <CarPlay/CarPlay.h>

@implementation OACarPlayPurchaseViewController
{
    CPWindow *_window;
    UIViewController *_vc;
}

- (instancetype)initWithCarPlayWindow:(CPWindow *)window viewController:(UIViewController *)vc
{
    self = [super init];
    if (self) {
        _window = window;
        _vc = vc;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self attachToWindow];
}

- (void) attachToWindow
{
    if (_window && _vc)
    {
        [self addChildViewController:_vc];
        [self.view addSubview:_vc.view];
        [_vc didMoveToParentViewController:self];
        UIEdgeInsets insets = _window.safeAreaInsets;
        CGRect frame = self.view.frame;
        frame.origin.x = insets.left;
        frame.origin.y = insets.top;
        frame.size.width -= insets.right;
        frame.size.height -= insets.bottom;
        _vc.view.frame = frame;
        [_vc.view setNeedsUpdateConstraints];
        [_vc.view updateConstraintsIfNeeded];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    UIEdgeInsets insets = _window.safeAreaInsets;
    CGRect frame = self.view.frame;
    frame.origin.x = insets.left;
    frame.origin.y = insets.top;
    frame.size.width -= (insets.right + insets.left);
    frame.size.height -= (insets.bottom + insets.top);
    _vc.view.frame = frame;
    [_vc.view setNeedsUpdateConstraints];
    [_vc.view updateConstraintsIfNeeded];
}

@end
