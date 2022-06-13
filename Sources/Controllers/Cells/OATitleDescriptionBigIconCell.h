//
//  OATitleDescriptionBigIconCell.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATitleDescriptionBigIconCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleVerticalConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomNoDescriptionMargin;

- (void)showDescription:(BOOL)show;

@end
