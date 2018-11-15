//
//  OACompoundViewController.h
//  OsmAnd
//
//  Created by Paul on 15.11.18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASuperViewController.h"

@interface OACompoundViewController : OASuperViewController

-(UIView *) getTopView;
-(UIView *) getMiddleView;
-(UIView *) getBottomView;
-(void) applySafeAreaMargins:(CGSize)screenSize toolBarHeight:(CGFloat)toolBarHeight;
-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;

@end
