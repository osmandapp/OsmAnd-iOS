//
//  OAMenuSimpleCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMenuSimpleCell.h"
#import "OAUtilities.h"

@implementation OAMenuSimpleCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) updateConstraints
{
    self.textHeightPrimary.active = self.descriptionView.hidden;
    self.textHeightSecondary.active = !self.descriptionView.hidden;
    self.textBottomMargin.active = self.descriptionView.hidden;
    self.descrTopMargin.active = !self.descriptionView.hidden;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        res = res || self.textHeightPrimary.active != self.descriptionView.hidden;
        res = res || self.textHeightSecondary.active != !self.descriptionView.hidden;
        res = res || self.textBottomMargin.active != self.descriptionView.hidden;
        res = res || self.descrTopMargin.active != !self.descriptionView.hidden;
    }
    return res;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)changeHeight:(BOOL)higher
{
    self.textTopPrimaryMargin.active = !higher;
    self.textTopSecondaryMargin.active = higher;
    self.textBottomPrimaryMargin.active = !higher;
    self.textBottomSecondaryMargin.active = higher;
}

@end
