//
//  OAPasswordInputFieldCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPasswordInputFieldCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define defaultCellHeight 60.0
#define titleTextWidthDelta 50.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;
static UIFont *_descFont;

@implementation OAPasswordInputFieldCell
{
    BOOL _shouldShowPassword;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _shouldShowPassword = NO;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    CGFloat textX = 16.0;
    CGFloat textWidth = w - textX;
    CGFloat titleHeight = _inputField.intrinsicContentSize.height;
    CGFloat cellHeight = MAX(defaultCellHeight, titleHeight);
    
    self.inputField.frame = CGRectMake(textX, 0.0, textWidth - textX, cellHeight);
    self.togglePasswordButton.frame = CGRectMake(w - 32 - self.togglePasswordButton.frame.size.width, cellHeight / 2 - self.togglePasswordButton.frame.size.height / 2, self.togglePasswordButton.frame.size.width, self.togglePasswordButton.frame.size.height);
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:16.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}

- (void) setupPasswordButton
{
    _togglePasswordButton.tintColor = UIColorFromRGB(bottomSheetPrimaryColor);
    UIImage *img = [[UIImage imageNamed:_shouldShowPassword ? @"ic_custom_hide" : @"ic_custom_show"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_togglePasswordButton setImage:img  forState:UIControlStateNormal];
}

- (IBAction)showHideButtonPressed:(id)sender
{
    _shouldShowPassword = !_shouldShowPassword;
    [_inputField setSecureTextEntry:!_shouldShowPassword];
    [UIView animateWithDuration:0.5 delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        UIImage *img = [[UIImage imageNamed:_shouldShowPassword ? @"ic_custom_hide" : @"ic_custom_show"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_togglePasswordButton setImage:img  forState:UIControlStateNormal];
    } completion:nil];
}

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    _inputField.backgroundColor = [UIColor clearColor];
}

@end
