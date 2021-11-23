//
//  OATitleDescriptionIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleDescriptionIconRoundCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UILabel *descrView;

@property (nonatomic) UIColor *iconColorNormal;
@property (nonatomic) UIColor *textColorNormal;

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

- (void) roundCorners:(BOOL)topCorners
        bottomCorners:(BOOL)bottomCorners
        hasLeftMargin:(BOOL)leftMargin;

@end
