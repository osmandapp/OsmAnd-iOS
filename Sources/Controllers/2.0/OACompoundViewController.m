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

@interface OACompoundViewController ()

@end

@implementation OACompoundViewController

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

-(void) applyCorrectSizes:(CGSize)screenSize toolBarHeight:(CGFloat)toolBarHeight
{
    [OAUtilities adjustViewsToNotch:screenSize topView:[self getTopView] middleView:[self getMiddleView]
                         bottomView:toolBarHeight == 0 ? nil : [self getBottomView] navigationBarHeight:defaultNavBarHeight toolBarHeight:toolBarHeight];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applyCorrectSizes:size toolBarHeight:defaultToolBarHeight];
    } completion:nil];
}

@end
