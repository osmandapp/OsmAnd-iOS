//
//  OASubscribeEmailView.h
//  OsmAnd
//
//  Created by Alexey on 28/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OASubscribeEmailViewDelegate <NSObject>

@required
- (void) subscribeEmailButtonPressed;

@end

@interface OASubscribeEmailView : UIView

@property (nonatomic, weak) id<OASubscribeEmailViewDelegate> delegate;

- (CGRect) updateFrame:(CGFloat)width margin:(CGFloat)margin;
- (void) updateColorForCALayer;

@end

NS_ASSUME_NONNULL_END
