//
//  OABaseMenuController.h
//  OsmAnd
//
//  Created by Alexey on 26/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EContextMenuAnimation)
{
    EContextMenuAnimationSlideInLeft = 0,
    EContextMenuAnimationSlideInBottom,
    EContextMenuAnimationSlideOutLeft,
    EContextMenuAnimationSlideOutBottom
};

@interface OABaseMenuController : NSObject

- (BOOL) isLight;
- (void) updateNightMode;
- (BOOL) isLandscapeLayout;
- (int) getLandscapeWidth;
- (float) getHalfScreenMaxHeightKoef;
- (EContextMenuAnimation) getSlideInAnimation;
- (EContextMenuAnimation) getSlideOutAnimation;

@end
