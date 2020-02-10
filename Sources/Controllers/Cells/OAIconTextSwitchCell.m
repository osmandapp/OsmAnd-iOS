//
//  OAIconTextSwitchCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAIconTextSwitchCell.h"
#import "OAUtilities.h"

@implementation OAIconTextSwitchCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}
- (void)updateConstraints
{
    _descHeightPrimary.active = !self.descView.isHidden;
    _descHeightSecondary.active = self.descView.isHidden;
    _textHeightPrimary.active = !self.descView.isHidden;
    _textHeightSecondary.active = self.descView.isHidden;
    
    [super updateConstraints];
}

- (void) showDescription:(BOOL)show
{
//    _descHeightPrimary.active = show;
//    _descHeightSecondary.active = !show;
//    _textHeightPrimary.active = show;
//    _textHeightSecondary.active = !show;
}


@end
