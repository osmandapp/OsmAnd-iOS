//
//  OAResultMatcher.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAResultMatcher.h"

@implementation OAResultMatcher

- (BOOL) publish:(id)object
{
    if (_publishFunction)
        return _publishFunction(&object);

    return NO;
}

- (BOOL) isCancelled
{
    if (_cancelledFunction)
        return _cancelledFunction();

    return NO;
}

- (instancetype)initWithPublishFunc:(OAResultMatcherPublish)pFunction cancelledFunc:(OAResultMatcherIsCancelled)cFunction
{
    self = [super init];
    if (self) {
        _publishFunction = pFunction;
        _cancelledFunction = cFunction;
    }
    return self;
}

@end
