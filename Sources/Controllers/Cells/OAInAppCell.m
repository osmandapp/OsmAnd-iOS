//
//  OAInAppCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAInAppCell.h"
#import "OAUtilities.h"

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

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [_btnPrice sizeToFit];
    CGSize priceSize = CGSizeMake(MAX(kPriceMinTextWidth, _btnPrice.bounds.size.width + (_btnPrice.titleLabel.text.length > 0 ? kPriceTextInset * 2.0 : 0.0)), kPriceMinTextHeight);
    CGRect priceFrame = _btnPrice.frame;
    priceFrame.origin = CGPointMake(self.bounds.size.width - priceSize.width - kPriceRectBorder, self.bounds.size.height / 2.0 - priceSize.height / 2.0);
    priceFrame.size = priceSize;
    _btnPrice.frame = priceFrame;

    CGRect titleFrame = _lbTitle.frame;
    CGFloat titleY = 18.0;
    if (_lbDescription.text.length == 0)
        titleY = 26.0;
    
    _lbTitle.frame = CGRectMake(74.0, titleY, _btnPrice.frame.origin.x - titleFrame.origin.x - 8.0, titleFrame.size.height);

    CGRect descFrame = _lbDescription.frame;
    _lbDescription.frame = CGRectMake(75.0, 36.0, _btnPrice.frame.origin.x - descFrame.origin.x - 8.0, descFrame.size.height);
    
    CGSize s = [_lbDescription.text boundingRectWithSize:CGSizeMake(_lbDescription.frame.size.width, 10000.0)
                                   options:NSStringDrawingUsesLineFragmentOrigin
                                attributes:@{NSFontAttributeName : _lbDescription.font}
                                   context:nil].size;
    
    if (s.height < 21.0) {
        _lbDescription.frame = CGRectMake(_lbDescription.frame.origin.x, _lbDescription.frame.origin.y, _lbDescription.frame.size.width, 21.0);
    } else {
        _lbDescription.frame = CGRectMake(_lbDescription.frame.origin.x, _lbDescription.frame.origin.y, _lbDescription.frame.size.width, 36.0);
    }

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

