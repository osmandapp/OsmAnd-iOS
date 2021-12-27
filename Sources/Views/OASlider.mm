//
//  OASlider.mm
//  OsmAnd
//
//  Created by Skalii on 18.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASlider.h"

@interface OASlider ()

@property (assign, nonatomic) IBInspectable CGFloat trackHeight;
@property (assign, nonatomic) BOOL createdFromIB;

@end

@implementation OASlider

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.trackHeight = 4.;
        self.createdFromIB = YES;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    if (self.createdFromIB)
    {
        //add anything required in IB-define way
    }
}

- (void)setTrackHeight:(CGFloat)trackHeight
{
    _trackHeight = trackHeight;
    [self setNeedsDisplay];
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    CGRect defaultBounds = [super trackRectForBounds:bounds];
    return CGRectMake(
            defaultBounds.origin.x,
            defaultBounds.origin.y,
            defaultBounds.size.width,
            self.trackHeight
    );
}

@end
