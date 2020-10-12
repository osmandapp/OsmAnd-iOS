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
}

@end
