//
//  OAPublicTransportCollapsableCell.m
//  OsmAnd
//
//  Created by Paul on 17/10/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAPublicTransportCollapsableCell.h"
#import "OAUtilities.h"

@implementation OAPublicTransportCollapsableCell

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
    _descHeightPrimary.active = !self.descView.hidden;
    _descHeightSecondary.active = self.descView.hidden;
    _textHeightPrimary.active = !self.descView.hidden;
    _textHeightSecondary.active = self.descView.hidden;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    self.descView.hidden = !self.descView.text || self.descView.text.length == 0;
    if (!res)
    {
        res = res || self.textHeightPrimary.active != self.descView.hidden;
        res = res || self.textHeightSecondary.active != !self.descView.hidden;
        res = res || self.descHeightPrimary.active != self.descView.hidden;
        res = res || self.descHeightSecondary.active != !self.descView.hidden;
    }
    return res;
}

@end
