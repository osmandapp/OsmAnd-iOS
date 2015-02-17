//
//  OAGPXElevationTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXElevationTableViewCell.h"

@implementation OAGPXElevationTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self updateLayout];
}

- (void) updateLayout
{
    CGFloat left = 15.0;
    CGFloat right = self.contentView.frame.size.width - 14.0;
    CGFloat mid = self.contentView.frame.size.height / 2.0;
    
    [self.textView sizeToFit];
    [self.elev1View sizeToFit];
    [self.elev2View sizeToFit];
    
    self.textView.frame = CGRectMake(left, mid - self.textView.frame.size.height / 2.0, self.textView.frame.size.width, self.textView.frame.size.height);
    
    if (self.showUpDown) {
        
        CGFloat x = right - self.elev2View.frame.size.width;
        
        self.elev2View.frame = CGRectMake(x, mid - self.elev2View.frame.size.height / 2.0, self.elev2View.frame.size.width, self.elev2View.frame.size.height);
        
        if (self.showArrows) {
            x -= self.elev2ArrowView.frame.size.width - 2;
            self.elev2ArrowView.frame = CGRectMake(x, mid - self.elev2ArrowView.frame.size.height / 2.0, self.elev2ArrowView.frame.size.width, self.elev2ArrowView.frame.size.height);
        }
        
        x -= 10.0 + self.elev1View.frame.size.width;
        
        self.elev1View.frame = CGRectMake(x, mid - self.elev1View.frame.size.height / 2.0, self.elev1View.frame.size.width, self.elev1View.frame.size.height);

        if (self.showArrows) {
            x -= self.elev1ArrowView.frame.size.width - 2;
            self.elev1ArrowView.frame = CGRectMake(x, mid - self.elev1ArrowView.frame.size.height / 2.0, self.elev1ArrowView.frame.size.width, self.elev1ArrowView.frame.size.height);
        }

        self.elev1ArrowView.hidden = !self.showArrows;
        self.elev2ArrowView.hidden = !self.showArrows;
        self.elev2View.hidden = NO;
        
    } else {
        
        self.elev1ArrowView.hidden = YES;
        self.elev2ArrowView.hidden = YES;
        self.elev2View.hidden = YES;
        
        self.elev1View.frame = CGRectMake(right - self.elev1View.frame.size.width, mid - self.elev1View.frame.size.height / 2.0, self.elev1View.frame.size.width, self.elev1View.frame.size.height);
        
    }
}

@end
