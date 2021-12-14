//
//  OATitleIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleIconRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
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
