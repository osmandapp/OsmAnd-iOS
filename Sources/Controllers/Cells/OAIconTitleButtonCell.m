//
//  OAIconTitleButtonCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleButtonCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthDelta 108.0
#define maxButtonWidth 70.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;

@implementation OAIconTitleButtonCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta - maxButtonWidth;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
    
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    
    CGFloat textX = self.iconView.hidden ? 16.0 : 44.0 + 16.0;
    CGFloat textWidth = w - titleTextWidthDelta - maxButtonWidth;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.titleView.text];
    
    self.titleView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
}

-(void)showImage:(BOOL)show
{
    self.iconView.hidden = !show;
    [self setNeedsLayout];
}

- (void) setButtonText:(NSString *)text
{
    [self.buttonView setTitle:text forState:UIControlStateNormal];
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}

@end
