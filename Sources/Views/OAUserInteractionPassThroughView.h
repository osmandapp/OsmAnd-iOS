//
//  OAUserInteractionPassThroughView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAObservable;

@protocol OAUserInteractionPassThroughDelegate <NSObject>

- (BOOL)isTouchEventAllowedForView:(UIView *)view;

@end

@interface OAUserInteractionPassThroughView : UIView

@property (nonatomic, weak) id<OAUserInteractionPassThroughDelegate> delegate;
@property (readonly) OAObservable* didLayoutObservable;

@end
