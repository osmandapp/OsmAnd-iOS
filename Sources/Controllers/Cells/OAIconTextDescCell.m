//
//  OAIconTextDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIconTextDescCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 50.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OAIconTextDescCell

- (void)awakeFromNib {
    // Initialization code
}

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title value:value] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title value:(NSString *)value
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    
    if (!_valueTextFont)
        _valueTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
    
    CGFloat w = cellWidth / titleTextWidthKoef;
    CGFloat titleHeight = 0;
    if (title)
        titleHeight = [OAUtilities calculateTextBounds:title width:w font:_titleTextFont].height + textMarginVertical * 2;
    
    w = cellWidth / valueTextWidthKoef;
    CGFloat valueHeight = 0;
    if (value && value.length > 0)
        valueHeight = [OAUtilities calculateTextBounds:value width:w font:_valueTextFont].height + textMarginVertical * 2;
    
    return MAX(titleHeight, valueHeight);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)showImage:(BOOL)show
{
    if (show)
    {
        CGRect frame = CGRectMake(51.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
        
        frame = CGRectMake(51.0, self.descView.frame.origin.y, self.descView.frame.size.width, self.descView.frame.size.height);
        self.descView.frame = frame;
    }
    else
    {
        CGRect frame = CGRectMake(11.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
        
        frame = CGRectMake(11.0, self.descView.frame.origin.y, self.descView.frame.size.width, self.descView.frame.size.height);
        self.descView.frame = frame;
    }
}

@end
