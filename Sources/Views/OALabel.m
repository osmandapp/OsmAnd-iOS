//
//  OALabel.m
//  OsmAnd
//
//  Created by Skalii on 15.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OALabel.h"

@implementation OALabel
{
    UITapGestureRecognizer *_tapToCopyRecognizer;
    UILongPressGestureRecognizer *_longPressToCopyRecognizer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _tapToCopyRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonTapped:)];
    [self addGestureRecognizer:_tapToCopyRecognizer];
    _longPressToCopyRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonLongPressed:)];
    [self addGestureRecognizer:_longPressToCopyRecognizer];
}

- (void)onButtonTapped:(UIGestureRecognizer *)recognizer
{
    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
        [self.delegate onLabelTapped:self.tag];
}

- (void)onButtonLongPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
        [self.delegate onLabelLongPressed:self.tag];
}

@end
