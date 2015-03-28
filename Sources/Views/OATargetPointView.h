//
//  OATargetPointView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 03.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OANavigationController.h"

#define kOATargetPointViewHeightPortrait 125.0
#define kOATargetPointViewHeightLandscape 72.0

@class OATargetPoint;

@protocol OATargetPointViewDelegate;

@interface OATargetPointView : UIView

@property (nonatomic) OATargetPoint *targetPoint;
@property (nonatomic, assign) BOOL isAddressFound;
@property (strong, nonatomic) id<OATargetPointViewDelegate> delegate;

-(void)setMapViewInstance:(UIView*)mapView;
-(void)setNavigationController:(UINavigationController*)controller;

- (void)doLayoutSubviews;

@end


@protocol OATargetPointViewDelegate <NSObject>

-(void)targetPointAddFavorite;
-(void)targetPointShare;
-(void)targetPointDirection;
-(void)targetHide;
-(void)targetGoToPoint;

@end