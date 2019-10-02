//
//  OADestinationCollectionViewCell.m
//  OsmAnd
//
//  Created by Paul on 25/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OADestinationCollectionViewCell.h"

@implementation OADestinationCollectionViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    BOOL hasDescription = !_descrLabel.hidden && _descrLabel.text.length > 0;
    _descrLabel.hidden = !hasDescription;
    
    CGRect titleFrame = _titleLabel.frame;
    titleFrame.origin.x = 16.0;
    titleFrame.origin.y = hasDescription ? 9.0 : 19.0;
    _titleLabel.frame = titleFrame;
    
    if (hasDescription)
    {
        CGRect descrFrame = _descrLabel.frame;
        descrFrame.origin.x = 16.0;
        descrFrame.origin.y = CGRectGetMaxY(titleFrame) + 2.0;
        _descrLabel.frame = descrFrame;
    }
}

@end
