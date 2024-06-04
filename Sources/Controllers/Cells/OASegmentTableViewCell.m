//
//  OASegmentTableViewCell.m
//  OsmAnd
//
//  Created by igor on 12.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentTableViewCell.h"

@implementation OASegmentTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    for (UIView *view in self.subviews)
    {
        if ([NSStringFromClass(view.class) hasSuffix:@"CellSeparatorView"])
        {
            if (_hideTopSectionSeparator && view.frame.origin.y == 0)
                view.hidden = YES;
            else if (_hideBottomSectionSeparator && view.frame.origin.y > 0)
                view.hidden = YES;
            else
                view.hidden = NO;
        }
    }
}

@end
