//
//  OARadiusItemEx.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARadiusCellEx.h"

@implementation OARadiusCellEx
{
    UIFont *_fontRegular;
    UIFont *_fontBold;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _fontRegular = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    _fontBold = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
    
    _buttonLeft.titleLabel.numberOfLines = 2;
    _buttonRight.titleLabel.numberOfLines = 2;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void) setButton:(UIButton *)button title:(NSString *)title description:(NSString *)description
{
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", title, description]];
    
    [str addAttribute:NSForegroundColorAttributeName value:UIColor.blackColor range:NSMakeRange(0, title.length)];
    [str addAttribute:NSFontAttributeName value:_fontRegular range:NSMakeRange(0, title.length)];
    [str addAttribute:NSFontAttributeName value:_fontBold range:NSMakeRange(title.length, description.length)];
    [button setAttributedTitle:str forState:UIControlStateNormal];
}

- (void) setButtonLeftTitle:(NSString *)title description:(NSString *)description
{
    [self setButton:self.buttonLeft title:title description:description];
}

- (void) setButtonRightTitle:(NSString *)title description:(NSString *)description
{
    [self setButton:self.buttonRight title:title description:description];
}

@end
