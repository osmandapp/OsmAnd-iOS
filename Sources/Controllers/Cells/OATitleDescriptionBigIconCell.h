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
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleVerticalConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomNoDescriptionMargin;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleWithLeftIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleNoLeftIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleWithRightIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleNoRightIconConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionWithLeftIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionNoLeftIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionWithRightIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionNoRightIconConstraint;

- (void)showDescription:(BOOL)show;
- (void)showLeftIcon:(BOOL)show;
- (void)showRightIcon:(BOOL)show;

@end
