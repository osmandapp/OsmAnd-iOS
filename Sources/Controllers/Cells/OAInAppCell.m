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

    self.imgPrice.layer.cornerRadius = 4;
    self.imgPrice.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    [_lbPrice sizeToFit];
    CGSize priceSize = CGSizeMake(MAX(kPriceMinTextWidth, _lbPrice.bounds.size.width), MAX(kPriceMinTextHeight, _lbPrice.bounds.size.height));
    CGRect priceFrame = _lbPrice.frame;
    priceFrame.origin = CGPointMake(self.bounds.size.width - priceSize.width - kPriceRectBorder - kPriceTextInset, 25.0);
    priceFrame.size = priceSize;
    _lbPrice.frame = priceFrame;
    
    _imgPrice.frame = CGRectMake(priceFrame.origin.x - kPriceTextInset, priceFrame.origin.y, priceFrame.size.width + kPriceTextInset * 2.0, priceFrame.size.height);
    

    CGRect titleFrame = _lbTitle.frame;
    _lbTitle.frame = CGRectMake(74.0, 18.0, _imgPrice.frame.origin.x - titleFrame.origin.x - 8.0, titleFrame.size.height);

    CGRect descFrame = _lbDescription.frame;
    _lbDescription.frame = CGRectMake(75.0, 36.0, _imgPrice.frame.origin.x - descFrame.origin.x - 8.0, descFrame.size.height);
    
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
        self.lbPrice.text = @"";
        self.imgPrice.layer.borderWidth = 0;
        if (!disabled)
            self.imgPrice.image = [UIImage imageNamed:@"bt_bought_addon"];
        else
            self.imgPrice.image = [UIImage imageNamed:@"bt_bought_addon_disabled"];
    }
    else
    {
        self.imgPrice.layer.borderWidth = 0.8;
        self.imgPrice.layer.borderColor = [UIColor colorWithRed:0.992f green:0.561f blue:0.149f alpha:1.00f].CGColor;
        self.imgPrice.image = nil;
    }
}

@end

