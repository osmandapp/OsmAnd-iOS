//
//  OATextViewTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 10.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATextViewTableViewCell.h"

@implementation OATextViewTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    if ([_textView isDirectionRTL])
        _textView.textAlignment = NSTextAlignmentRight;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
