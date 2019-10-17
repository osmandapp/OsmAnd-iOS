//
//  OAHomeWorkCollectionViewCell.m
//  OsmAnd
//
//  Created by Paul on 25/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAHomeWorkCollectionViewCell.h"

@implementation OAHomeWorkCollectionViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect titleFrame = _titleLabel.frame;
    titleFrame.origin.x = 62.0;
    titleFrame.origin.y = 9.0;
    _titleLabel.frame = titleFrame;
    
    CGRect descrFrame = _descrLabel.frame;
    descrFrame.origin.x = 62.0;
    descrFrame.origin.y = CGRectGetMaxY(titleFrame) + 2.0;
    _descrLabel.frame = descrFrame;
}

@end
