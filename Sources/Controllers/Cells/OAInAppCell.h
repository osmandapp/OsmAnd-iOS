//
//  OAInAppCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPriceTextInset 4.0
#define kPriceMinTextWidth 46.0
#define kPriceMinTextHeight 26.0
#define kPriceRectBorder 15.0

@interface OAInAppCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UILabel *lbPrice;

@property (weak, nonatomic) IBOutlet UIView *imgIconBackground;
@property (weak, nonatomic) IBOutlet UIImageView *imgIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgPrice;

-(void)setPurchased:(BOOL)purchased disabled:(BOOL)disabled;

@end
