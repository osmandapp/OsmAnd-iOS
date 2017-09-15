//
//  OARoutingProgressView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingProgressView.h"

@implementation OARoutingProgressView

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self)
        {
            [self.progressBarView setProgress:0];

            // drop shadow
            self.layer.cornerRadius = 5.0;
            [self.layer setShadowColor:[UIColor blackColor].CGColor];
            [self.layer setShadowOpacity:0.3];
            [self.layer setShadowRadius:2.0];
            [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            [self.progressBarView setProgress:0];
            self.frame = frame;
            
            // drop shadow
            self.layer.cornerRadius = 5.0;
            [self.layer setShadowColor:[UIColor blackColor].CGColor];
            [self.layer setShadowOpacity:0.3];
            [self.layer setShadowRadius:2.0];
            [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
        }
    }
    return self;
}

- (void) setProgress:(float)progress
{
    [self.progressBarView setProgress:progress];
}

@end
