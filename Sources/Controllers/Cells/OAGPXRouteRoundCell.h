//
//  OAGPXRouteRoundCell.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAGPXRouteRoundCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *contentContainer;
@property (strong, nonatomic) IBOutlet UILabel *fileName;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *wptLabel;
@property (strong, nonatomic) IBOutlet UIImageView *rightIconImageVIew;
@property (strong, nonatomic) IBOutlet UIImageView *distanceImageView;
@property (strong, nonatomic) IBOutlet UIImageView *timeImageView;
@property (strong, nonatomic) IBOutlet UIImageView *wptImageView;
@property (strong, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeightConstraint;

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners;

@end
