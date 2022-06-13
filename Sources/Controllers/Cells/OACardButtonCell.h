//
//  OACardButtonCell.h
//  OsmAnd
//
//  Created by Skalii on 27.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACardButtonCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIButton *buttonView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLeftMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleNoIconLeftMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomNoDescriptionMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionLeftMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionNoIconLeftMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonLeftMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonNoIconLeftMargin;

- (void)showIcon:(BOOL)show;
- (void)showDescription:(BOOL)show;

@end
