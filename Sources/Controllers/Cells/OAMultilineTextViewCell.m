//
//  OAMultilineTextViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMultilineTextViewCell.h"

@implementation OAMultilineTextViewCell

static UIFont *_titleFont;

+ (NSString *)getCellIdentifier
{
    return @"OAMultilineTextViewCell";
}

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

@end
