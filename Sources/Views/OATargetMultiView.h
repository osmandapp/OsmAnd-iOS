//
//  OATargetMultiView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATargetPoint.h"

@class SelectedMapObject;

@interface OATargetMultiView : UIView

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIButton *headerCloseButton;
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;

@property (nonatomic) NSArray<OATargetPoint *> *targetPoints;

@property (nonatomic) NSArray<SelectedMapObject *> *selectedMapObjects;
@property (nonatomic) CLLocation *touchPoint;

@property (nonatomic) OATargetPointType activeTargetType;
- (void)show:(BOOL)animated onComplete:(void (^)(void))onComplete;
- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;

- (void)transitionToSize;

@end
