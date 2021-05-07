//
//  OADividerCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OADividerCell : OABaseCell

@property (nonatomic) CGFloat dividerHight;
@property (nonatomic) UIEdgeInsets dividerInsets;
@property (nonatomic) UIColor *dividerColor;

@property (nonatomic, readonly) CGFloat cellHeight;

+ (CGFloat) cellHeight:(CGFloat)dividerHight dividerInsets:(UIEdgeInsets)dividerInsets;

@end
