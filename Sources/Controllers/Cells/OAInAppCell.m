//
//  OAInAppCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAInAppCell.h"

#define kPriceTextInset 4.0
#define kPriceMinTextWidth 46.0
#define kPriceMinTextHeight 26.0
#define kPriceRectBorder 15.0

@implementation OAInAppCell

- (void)awakeFromNib {

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
    priceFrame.origin = CGPointMake(self.contentView.bounds.size.width - priceSize.width - kPriceRectBorder - kPriceTextInset, 25.0);
    priceFrame.size = priceSize;
    _lbPrice.frame = priceFrame;
    
    _imgPrice.frame = CGRectMake(priceFrame.origin.x - kPriceTextInset, priceFrame.origin.y, priceFrame.size.width + kPriceTextInset * 2.0, priceFrame.size.height);
    

    CGRect titleFrame = _lbTitle.frame;
    titleFrame.size = CGSizeMake(_imgPrice.frame.origin.x - titleFrame.origin.x - 8.0, titleFrame.size.height);
    _lbTitle.frame = titleFrame;

    CGRect descFrame = _lbDescription.frame;
    descFrame.size = CGSizeMake(_imgPrice.frame.origin.x - descFrame.origin.x - 8.0, descFrame.size.height);
    _lbDescription.frame = descFrame;
    
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

-(void)setPurchased:(BOOL)purchased
{
    if (purchased) {
        self.lbPrice.text = @"";
        self.imgPrice.layer.borderWidth = 0;
        self.imgPrice.image = [UIImage imageNamed:@"bt_bought_addon"];
        
    } else {
        self.imgPrice.layer.borderWidth = 0.8;
        self.imgPrice.layer.borderColor = [UIColor colorWithRed:0.992f green:0.561f blue:0.149f alpha:1.00f].CGColor;
        self.imgPrice.image = nil;
    }

}

@end

