//
//  OACompoundViewController.m
//  OsmAnd
//
//  Created by Paul on 15.11.18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAUtilities.h"
#import "OASizes.h"

@interface OACompoundViewController () <UIGestureRecognizerDelegate>

@end

@implementation OACompoundViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
}

-(UIView *) getTopView
{
    return nil;
}

-(UIView *) getMiddleView
{
    return nil;
}

-(UIView *) getBottomView
{
    return nil;
}

-(CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

-(CGFloat) getToolBarHeight
{
    return 0;
}

-(void) applySafeAreaMargins
{
    [self applySafeAreaMargins:self.view.frame.size];
}

-(void) applySafeAreaMargins:(CGSize)screenSize
{
    CGFloat toolBarHeight = [self getToolBarHeight];
    [OAUtilities adjustViewsToNotch:screenSize topView:[self getTopView] middleView:[self getMiddleView]
                         bottomView:toolBarHeight == 0 ? nil : [self getBottomView] navigationBarHeight:[self getNavBarHeight] toolBarHeight:toolBarHeight];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins:self.view.frame.size];
    } completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
