//
//  OAInAppCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAInAppCell.h"

@implementation OAInAppCell

- (void)awakeFromNib {

    self.imgIconBackground.layer.cornerRadius = 3;
    self.imgIconBackground.layer.masksToBounds = YES;

    self.btnPrice.layer.cornerRadius = 4;
    self.btnPrice.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)setPurchased:(BOOL)purchased disabled:(BOOL)disabled
{
    if (purchased)
    {
        [self.btnPrice setTitle:@"" forState:UIControlStateNormal];
        if (!disabled)
        {
            self.btnPrice.layer.borderWidth = 0.0;
            self.btnPrice.backgroundColor = UIColorFromRGB(0xff8f00);
            self.btnPrice.tintColor = [UIColor whiteColor];
            [self.btnPrice setImage:[UIImage imageNamed:@"ic_checkmark_small_enable"] forState:UIControlStateNormal];
        }
        else
        {
            self.btnPrice.layer.borderWidth = 0.8;
            self.btnPrice.layer.borderColor = UIColorFromRGB(0xff8f00).CGColor;
            self.btnPrice.backgroundColor = [UIColor clearColor];
            self.btnPrice.tintColor = UIColorFromRGB(0xff8f00);
            [self.btnPrice setImage:[UIImage imageNamed:@"ic_checkmark_small_enable"] forState:UIControlStateNormal];
        }
    }
    else
    {
        self.btnPrice.layer.borderWidth = 0.8;
        self.btnPrice.layer.borderColor = UIColorFromRGB(0xff8f00).CGColor;
        self.btnPrice.backgroundColor = [UIColor clearColor];
        self.btnPrice.tintColor = UIColorFromRGB(0xff8f00);
        [self.btnPrice setImage:nil forState:UIControlStateNormal];
    }
}

@end

