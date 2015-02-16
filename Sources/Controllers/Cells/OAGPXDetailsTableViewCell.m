//
//  OAGPXDetailsTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDetailsTableViewCell.h"

@implementation OAGPXDetailsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [self updateLayout];
}

- (void) updateLayout
{
    CGFloat left = 15.0;
    CGFloat right = self.contentView.frame.size.width - 14.0;
    CGFloat mid = self.contentView.frame.size.height / 2.0;
    
    [self.textView sizeToFit];
    [self.descView sizeToFit];
    
    self.textView.frame = CGRectMake(left, mid - self.textView.frame.size.height / 2.0, self.textView.frame.size.width, self.textView.frame.size.height);
    self.descView.frame = CGRectMake(right - self.descView.frame.size.width, mid - self.descView.frame.size.height / 2.0, self.descView.frame.size.width, self.descView.frame.size.height);
}


@end
