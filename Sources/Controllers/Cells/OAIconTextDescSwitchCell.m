//
//  OAIconTextDescButtonTableViewCell.m
//  OsmAnd
//
//  Created by igor on 18.02.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconTextDescSwitchCell.h"

@implementation OAIconTextDescSwitchCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.dividerView.layer setCornerRadius:0.5f];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
