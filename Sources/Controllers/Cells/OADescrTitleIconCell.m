//
//  OADescrTitleIconCell.m
//  OsmAnd
//
//  Created by Paul on 17/10/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OADescrTitleIconCell.h"
#import "OAUtilities.h"

@implementation OADescrTitleIconCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) updateConstraints
{
    self.descView.hidden = !self.descView.text || self.descView.text.length == 0;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    self.descView.hidden = !self.descView.text || self.descView.text.length == 0;
    return res;
}

@end
