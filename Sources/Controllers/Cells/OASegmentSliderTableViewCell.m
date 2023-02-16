//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"

@implementation OASegmentSliderTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];

    if ([self isDirectionRTL])
    {
        self.topRightLabel.textAlignment = NSTextAlignmentLeft;
        self.bottomRightLabel.textAlignment = NSTextAlignmentLeft;
    }
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)showLabels:(BOOL)topLeft topRight:(BOOL)topRight bottomLeft:(BOOL)bottomLeft bottomRight:(BOOL)bottomRight;
{
    self.topLeftLabel.hidden = !topLeft;
    self.topRightLabel.hidden = !topRight;
    self.bottomLeftLabel.hidden = !bottomLeft;
    self.bottomRightLabel.hidden = !bottomRight;

    UIFont *bottomLabelsFont = [UIFont scaledSystemFontOfSize:topLeft || topRight ? 15. : 17.];
    self.bottomLeftLabel.font = bottomLabelsFont;
    self.bottomRightLabel.font = bottomLabelsFont;
}

- (void)updateConstraints
{
    BOOL hasLeftTopLabel = !self.topLeftLabel.hidden;
    BOOL hasRightTopLabel = !self.topRightLabel.hidden;
    BOOL hasTopLabels = hasLeftTopLabel || hasRightTopLabel;

    BOOL hasLeftBottomLabel = !self.bottomLeftLabel.hidden;
    BOOL hasRightBottomLabel = !self.bottomRightLabel.hidden;
    BOOL hasBottomLabels = hasLeftBottomLabel || hasRightBottomLabel;

    self.sliderLabelsTopConstraint.active = hasTopLabels;
    self.sliderNoLabelsTopConstraint.active = !hasTopLabels;

    self.sliderLabelsBottomConstraint.constant = hasTopLabels ? 7. : 13.;
    self.sliderLabelsBottomConstraint.active = hasBottomLabels;
    self.sliderNoLabelsBottomConstraint.active = !hasBottomLabels;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasLeftTopLabel = !self.topLeftLabel.hidden;
        BOOL hasRightTopLabel = !self.topRightLabel.hidden;
        BOOL hasTopLabels = hasLeftTopLabel || hasRightTopLabel;

        BOOL hasLeftBottomLabel = !self.bottomLeftLabel.hidden;
        BOOL hasRightBottomLabel = !self.bottomRightLabel.hidden;
        BOOL hasBottomLabels = hasLeftBottomLabel || hasRightBottomLabel;

        res = res || self.sliderLabelsTopConstraint.active != hasTopLabels;
        res = res || self.sliderNoLabelsTopConstraint.active != !hasTopLabels;

        res = res || self.sliderLabelsBottomConstraint.constant != (hasTopLabels ? 7. : 13.);
        res = res || self.sliderLabelsBottomConstraint.active != hasBottomLabels;
        res = res || self.sliderNoLabelsBottomConstraint.active != !hasBottomLabels;
    }
    return res;
}

@end
