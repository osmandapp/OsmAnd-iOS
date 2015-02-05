//
//  OAViewTextTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 21.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAViewTextTableViewCell.h"

@implementation OAViewTextTableViewCell

- (void)awakeFromNib {
    self.viewView.layer.cornerRadius = 10;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    UIColor *prevColor = self.viewView.backgroundColor;
    
    [super setSelected:selected animated:animated];

    self.viewView.backgroundColor = prevColor;
}

-(void) setColor:(UIColor*)color {
    
    [self.viewView setBackgroundColor:color];
    
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    if (red > 0.95 && green > 0.95 && blue > 0.95) {
        self.viewView.layer.borderColor = [[UIColor blackColor] CGColor];
        self.viewView.layer.borderWidth = 0.8;
    } else {
        self.viewView.layer.borderWidth = 0;
    }

}

@end
