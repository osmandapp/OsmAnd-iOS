//
//  OALargeImageTitleDescrTableViewCell.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OALargeImageTitleDescrTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *button;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionWithButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descriptionNoButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;

- (void)showButton:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
