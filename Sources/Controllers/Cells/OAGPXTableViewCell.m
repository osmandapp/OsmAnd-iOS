//
//  OAGPXTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXTableViewCell.h"

@implementation OAGPXTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self updateLayout];
}

- (void) updateLayout
{    
    [self.descriptionDistanceView sizeToFit];
    [self.descriptionPointsView sizeToFit];
    
    CGRect distIconFrame = self.distIconView.frame;
    CGRect pointsIconFrame = self.pointsIconView.frame;
    CGRect descDistFrame = self.descriptionDistanceView.frame;
    CGRect descPointsFrame = self.descriptionPointsView.frame;
    
    CGFloat x = distIconFrame.origin.x;
    CGFloat midX = 36.0;
    CGFloat dX = 3.0;
    CGFloat distIconWidth = distIconFrame.size.width;
    CGFloat pointsIconWidth = pointsIconFrame.size.width;

    self.distIconView.frame = CGRectMake(x, midX - distIconFrame.size.height / 2.0, distIconWidth, distIconFrame.size.height);
    x += distIconWidth + dX;
    self.descriptionDistanceView.frame = CGRectMake(x, midX - descDistFrame.size.height / 2.0, descDistFrame.size.width, descDistFrame.size.height);
    x += descDistFrame.size.width + dX;
    self.pointsIconView.frame = CGRectMake(x, midX - pointsIconFrame.size.height / 2.0, pointsIconWidth, pointsIconFrame.size.height);
    x += pointsIconWidth + dX;
    self.descriptionPointsView.frame = CGRectMake(x, midX - descPointsFrame.size.height / 2.0, descPointsFrame.size.width, descPointsFrame.size.height);
    
}

@end
