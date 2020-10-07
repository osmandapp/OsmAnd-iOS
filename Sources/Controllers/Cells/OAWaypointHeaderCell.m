//
//  OAWaypointHeader.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointHeaderCell.h"
#import "OAUtilities.h"

#define titleTextWidthDelta 44.0
#define defaultCellHeight 44.0
#define textMarginVertical 5.0

@implementation OAWaypointHeaderCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateConstraints
{
    _leftTitleMarginNoProgress.active = self.progressView.hidden;
    _leftTitleMarginWithProgressView.active = !self.progressView.hidden;
    [super updateConstraints];
}

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    UIFont *titleFont = [UIFont systemFontOfSize:16.0];
    return [OAUtilities calculateTextBounds:text width:width font:titleFont].height + textMarginVertical;
}

@end
