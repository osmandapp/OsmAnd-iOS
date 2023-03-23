//
//  OAShapeLayer.m
//  OsmAnd Maps
//
//  Created by Paul on 23.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAShapeLayer.h"

@implementation OAShapeLayer

- (id<CAAction>)actionForKey:(NSString *)event {
    if ([event isEqualToString:@"path"]) {
        CABasicAnimation *animation = [CABasicAnimation
            animationWithKeyPath:event
        ];
        animation.duration = [CATransaction animationDuration];
        animation.timingFunction = [CATransaction animationTimingFunction];
        return animation;
    }
    return [super actionForKey:event];
}

@end
