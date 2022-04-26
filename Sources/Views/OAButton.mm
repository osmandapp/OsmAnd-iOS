//
//  OAButton.mm
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAButton.h"

@implementation OAButton
{
    UITapGestureRecognizer *_tapRecognizer;
    UILongPressGestureRecognizer *_longPressRecognizer;
}

- (instancetype) initWithFrame:(CGRect)frame
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
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonTapped:)];
    [self addGestureRecognizer:_tapRecognizer];
    _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonLongPressed:)];
    [self addGestureRecognizer:_longPressRecognizer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.centerVertically)
        [self applyVerticalLayout];
}

- (void)applyVerticalLayout
{
    CGFloat spacingExt = 26.0;
    if (self.extraSpacing)
        spacingExt = 30.0;

    // the space between the image and text
    CGFloat spacing = 6.0;

    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = self.imageView.image.size;
    BOOL isRTL = [self isDirectionRTL];
    self.titleEdgeInsets = UIEdgeInsetsMake(
            0.0,
            isRTL ? 0.0 : - imageSize.width,
            - (spacingExt + spacing),
            isRTL ? - imageSize.width : 0.0);

    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width, self.titleLabel.frame.size.height * 2)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:@{NSFontAttributeName : self.titleLabel.font}
                                                          context:nil].size;
    self.imageEdgeInsets = UIEdgeInsetsMake(
            -(titleSize.height + spacing),
            isRTL ? -titleSize.width : 0.0f,
            0.0f,
            isRTL ? 0.0f : -titleSize.width);

    // increase the content height to avoid clipping
    CGFloat edgeOffset = fabsf(titleSize.height - imageSize.height) / 2.0;
    self.contentEdgeInsets = UIEdgeInsetsMake(edgeOffset, 0.0, edgeOffset, 0.0);

    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)onButtonTapped:(UIGestureRecognizer *)recognizer
{
    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
        [self.delegate onButtonTapped:self.tag];
}

- (void)onButtonLongPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
        [self.delegate onButtonLongPressed:self.tag];
}

@end
