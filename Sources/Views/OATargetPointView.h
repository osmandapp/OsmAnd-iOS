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

@protocol OATargetPointViewDelegate;

@interface OATargetPointView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, assign) BOOL isAddressFound;

@property (strong, nonatomic) id<OATargetPointViewDelegate> delegate;

-(void)setAddress:(NSString*)address;
-(void)setPointLat:(double)lat Lon:(double)lon andTouchPoint:(CGPoint)touchPoint;

-(void)setMapViewInstance:(UIView*)mapView;
-(void)setNavigationController:(UINavigationController*)controller;

- (void)doLayoutSubviews;

@end


@protocol OATargetPointViewDelegate <NSObject>

-(void)targetPointAddFavorite;
-(void)targetPointShare;
-(void)targetPointDirection;

@end