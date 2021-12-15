//
//  OATitleIconRoundCell.h
//  OsmAnd
//
//  Created by Skalii on 04.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleSwitchRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *switchView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *separatorView;

@property (nonatomic) UIColor *textColorNormal;

+ (CGFloat)getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth;

- (void)roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

- (void) roundCorners:(BOOL)topCorners
        bottomCorners:(BOOL)bottomCorners
        hasLeftMargin:(BOOL)leftMargin;

@end
