//
//  OAPointWithRegionTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 19.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAPointWithRegionTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (weak, nonatomic) IBOutlet UIView *locationContainerView;
@property (weak, nonatomic) IBOutlet UIView *directionContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *directionIconView;
@property (weak, nonatomic) IBOutlet UILabel *directionTextView;
@property (weak, nonatomic) IBOutlet UIView *locationSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *regionTextView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleWithLocationConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleNoLocationConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *directionWithRegionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *directionNoRegionConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionWithDirectionConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *regionNoDirectionConstraint;

- (void)setDirection:(NSString *)direction;
- (void)setRegion:(NSString *)region;

@end
