//
//  OAQuadItemsWithTitleDescIconCell.h
//  OsmAnd
//
//  Created by Skalii on 27.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAQuadItemsWithTitleDescIconCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *topLeftView;
@property (weak, nonatomic) IBOutlet UIView *topRightView;
@property (weak, nonatomic) IBOutlet UIView *bottomLeftView;
@property (weak, nonatomic) IBOutlet UIView *bottomRightView;

@property (weak, nonatomic) IBOutlet UILabel *topLeftTitle;
@property (weak, nonatomic) IBOutlet UILabel *topLeftDescription;
@property (weak, nonatomic) IBOutlet UIImageView *topLeftIcon;

@property (weak, nonatomic) IBOutlet UILabel *topRightTitle;
@property (weak, nonatomic) IBOutlet UILabel *topRightDescription;
@property (weak, nonatomic) IBOutlet UIImageView *topRightIcon;

@property (weak, nonatomic) IBOutlet UILabel *bottomLeftTitle;
@property (weak, nonatomic) IBOutlet UILabel *bottomLeftDescription;
@property (weak, nonatomic) IBOutlet UIImageView *bottomLeftIcon;

@property (weak, nonatomic) IBOutlet UILabel *bottomRightTitle;
@property (weak, nonatomic) IBOutlet UILabel *bottomRightDescription;
@property (weak, nonatomic) IBOutlet UIImageView *bottomRightIcon;

@end
