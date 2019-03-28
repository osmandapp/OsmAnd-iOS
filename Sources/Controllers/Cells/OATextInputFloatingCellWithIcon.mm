//
//  OATextInputFloatingCellWithIcon.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextInputFloatingCellWithIcon.h"
#import "OAUtilities.h"

#define defaultCellHeight 60.0
#define titleTextWidthDelta 44.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;
static UIFont *_descFont;

@implementation OATextInputFloatingCellWithIcon

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

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    
    CGFloat textX = 44.0;
    CGFloat textWidth = w - titleTextWidthDelta;
    CGFloat titleHeight = self.textField.intrinsicContentSize.height;
    
    self.textField.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
}

@end
