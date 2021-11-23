//
//  OAImageTextViewCell.m
//  OsmAnd
//
//  Created by igor on 24.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImageTextViewCell.h"
#import "OAColors.h"

@implementation OAImageTextViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    _descView.textContainerInset = UIEdgeInsetsZero;
    _descView.textContainer.lineFragmentPadding = 0;
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple),
                                     NSFontAttributeName: [UIFont systemFontOfSize:15.]};
    _descView.linkTextAttributes = linkAttributes;

    _extraDescView.textContainerInset = UIEdgeInsetsZero;
    _extraDescView.textContainer.lineFragmentPadding = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateConstraints
{
    CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
    CGFloat newIconHeight = (self.frame.size.width - 2 * 16 - OAUtilities.getLeftMargin) * ratio;
    BOOL hasExtraDesc = !self.extraDescView.hidden;

    self.iconViewHeight.constant = newIconHeight;
    self.descExtraTrailingConstraint.active = hasExtraDesc;
    self.descNoExtraTrailingConstraint.active = !hasExtraDesc;
    self.extraDescEqualDescWidth.active = hasExtraDesc;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
        CGFloat newIconHeight = (self.frame.size.width - 2 * 16 - OAUtilities.getLeftMargin) * ratio;
        BOOL hasExtraDesc = !self.extraDescView.hidden;

        res |= self.iconViewHeight.constant != newIconHeight;
        res |= self.descExtraTrailingConstraint.active != hasExtraDesc;
        res |= self.descNoExtraTrailingConstraint.active != !hasExtraDesc;
        res |= self.extraDescEqualDescWidth.active != hasExtraDesc;
    }
    return res;
}

- (void)showExtraDesc:(BOOL)show
{
    self.extraDescView.hidden = !show;
}

@end
