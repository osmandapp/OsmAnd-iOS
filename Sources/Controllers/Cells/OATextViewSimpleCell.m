//
//  OATextViewSimpleCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 26/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATextViewSimpleCell.h"

@implementation OATextViewSimpleCell

+ (NSString *) getCellIdentifier
{
    return @"OATextViewSimpleCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.textView setTextContainerInset:UIEdgeInsetsZero];
    self.textView.textContainer.lineFragmentPadding = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
