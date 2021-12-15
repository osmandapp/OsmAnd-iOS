//
//  OATitleTwoIconsRoundCell.h
//  OsmAnd
//
//  Created by nnngrach on 17/08/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATitleIconRoundCell.h"
#import <UIKit/UIKit.h>


@interface OATitleTwoIconsRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;

//@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@property (nonatomic) UIColor *iconColorNormal;
@property (nonatomic) UIColor *textColorNormal;

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth;

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

- (void) roundCorners:(BOOL)topCorners
        bottomCorners:(BOOL)bottomCorners
        hasLeftMargin:(BOOL)leftMargin;

@end
