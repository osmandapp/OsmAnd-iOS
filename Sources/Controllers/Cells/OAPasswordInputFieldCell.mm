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

+ (NSString *) getCellIdentifier
{
    return @"OAPasswordInputFieldCell";
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

- (void) setupPasswordButton
{
    _togglePasswordButton.tintColor = UIColorFromRGB(color_primary_purple);
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
