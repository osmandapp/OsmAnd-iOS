//
//  OAIconTextTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIconTextTableViewCell.h"

@implementation OAIconTextTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)showImage:(BOOL)show {
    
    if (show) {
        
        CGRect frame = CGRectMake(51.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
        
    } else {
        
        CGRect frame = CGRectMake(11.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
    }
}

@end
