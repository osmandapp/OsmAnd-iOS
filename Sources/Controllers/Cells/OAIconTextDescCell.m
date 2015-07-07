//
//  OAIconTextDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIconTextDescCell.h"

@implementation OAIconTextDescCell

- (void)awakeFromNib {
    // Initialization code
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
