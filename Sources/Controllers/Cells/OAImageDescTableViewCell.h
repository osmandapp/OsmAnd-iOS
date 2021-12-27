//
//  OAImageDescBTableViewCell.h
//  OsmAnd
//
//  Created by igor on 24.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAImageDescTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *descView;
@property (strong, nonatomic) IBOutlet UIImageView *iconView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconViewHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageBottomToLabelConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageBottomConstraint;

@end

