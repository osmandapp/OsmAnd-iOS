//
//  OAPublicTransportShieldsView.m
//  OsmAnd
//
//  Created by Paul on 13.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportShieldsView.h"

#define kShieldHeight 32

@implementation OAPublicTransportShieldsView
{
    NSArray<UIView *> *_shiledViews;
    NSNumber *_quantity;
}

/*
 Dummy data for testing. Remove when PT backend is ready
 */
- (instancetype) initWithNumber:(NSNumber *)quantity
{
    self = [super init];
    if (self)
    {
        _quantity = quantity;
    }
    return self;
}

- (void) buildViews
{
    f
}


@end
