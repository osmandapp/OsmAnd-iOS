//
//  OAQuickActionCell.m
//  OsmAnd
//
//  Created by Paul on 03/08/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionCell.h"
#import "OAUtilities.h"

@implementation OAQuickActionCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    self.layer.cornerRadius = 9.0;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    _imageView.frame = CGRectMake(w / 2 - 30.0 / 2, 8.0, 30.0, 30.0);
    CGFloat textViewY = CGRectGetMaxY(_imageView.frame) + 14.0;
    CGFloat textHeight = MIN(36.0,
                             [OAUtilities calculateTextBounds:_actionTitleView.text width:(w - 32.0)
                                                         font:_actionTitleView.font].height);
    _actionTitleView.frame = CGRectMake(16.0, textViewY, w - 32.0, textHeight);
}
@end
