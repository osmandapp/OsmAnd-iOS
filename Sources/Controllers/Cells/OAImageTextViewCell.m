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

+ (NSString *)getCellIdentifier
{
    return @"OAImageTextViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _descView.textContainerInset = UIEdgeInsetsZero;
    _descView.textContainer.lineFragmentPadding = 0;
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple),
                                     NSFontAttributeName: [UIFont systemFontOfSize:15.]};
    _descView.linkTextAttributes = linkAttributes;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateConstraints
{
    CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
    self.iconViewHeight.constant = (self.frame.size.width - 2 * 16 - OAUtilities.getLeftMargin) * ratio;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
        res |= self.iconViewHeight.constant != (self.frame.size.width - 2 * 16 - OAUtilities.getLeftMargin) * ratio;
    }
    return res;
}

@end
