//
//  OAActivityViewWithTitleCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 20.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAActivityViewWithTitleCell.h"

@implementation OAActivityViewWithTitleCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    for (UIView *view in self.subviews)
    {
        if ([view isEqual:self.contentView])
            continue;

        view.hidden = view.bounds.size.width == self.bounds.size.width;
    }
}

@end
