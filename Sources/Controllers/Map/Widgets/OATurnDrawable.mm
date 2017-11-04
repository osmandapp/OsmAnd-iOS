//
//  OATurnDrawable.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATurnDrawable.h"

@implementation OATurnDrawable
{
    BOOL _mini;
}

- (instancetype) initWithMini:(BOOL)mini
{
    self = [super init];
    if (self)
    {
        _mini = mini;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
