//
//  OAPointTableViewCell.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAPointTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *titleIcon;
@property (weak, nonatomic) IBOutlet UIImageView *titlePoiIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;
@property (weak, nonatomic) IBOutlet UILabel *distanceView;
@property (weak, nonatomic) IBOutlet UIView *cellView;
@property (weak, nonatomic) IBOutlet UIImageView *rightArrow;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleViewMarginWithIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleViewMarginNoIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewMarginWithIcon;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewMarginNoIcon;


@end
