//
//  OAGPXPointTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXPointTableViewCell.h"
#import "OAUtilities.h"

@implementation OAGPXPointTableViewCell

- (void)awakeFromNib {
    
    self.descView.textContainer.lineFragmentPadding = 0;
    if ([OAUtilities iosVersionIsAtLeast:@"7.0"]) {
        self.descView.textContainerInset = UIEdgeInsetsZero;
    } else {
        self.descView.contentInset = UIEdgeInsetsZero;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
