//
//  OAGPXTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAGPXTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UIImageView *distIconView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionDistanceView;
@property (weak, nonatomic) IBOutlet UIImageView *pointsIconView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionPointsView;

@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@end
