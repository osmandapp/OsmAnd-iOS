//
//  OAInAppCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

#define kPriceTextInset 6.0
#define kPriceMinTextWidth 53.0
#define kPriceMinTextHeight 26.0
#define kPriceRectBorder 15.0

@interface OAInAppCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIButton *btnPrice;

@property (weak, nonatomic) IBOutlet UIView *imgIconBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imgIcon;

-(void)setPurchased:(BOOL)purchased disabled:(BOOL)disabled;

@end
