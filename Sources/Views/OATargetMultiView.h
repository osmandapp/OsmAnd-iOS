//
//  OATargetMultiView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OATargetPoint.h"

@interface OATargetMultiView : UIView

@property (nonatomic) NSArray<OATargetPoint *> *targetPoints;
@property (nonatomic) OATargetPointType activeTargetType;
- (void)show:(BOOL)animated onComplete:(void (^)(void))onComplete;
- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete;

- (void)transitionToSize;

@end
