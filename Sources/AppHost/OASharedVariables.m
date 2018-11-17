//
//  OASharedVariables.m
//  OsmAnd
//
//  Created by Alexey on 04/08/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASharedVariables.h"
#import "OAUtilities.h"

@implementation OASharedVariables

static CGFloat _statusBarHeight = 20.0;

+ (void) setStatusBarHeight:(CGFloat)statusBarHeight
{
    _statusBarHeight = statusBarHeight;
}

+ (CGFloat) getStatusBarHeight
{
    return _statusBarHeight;
}

@end
