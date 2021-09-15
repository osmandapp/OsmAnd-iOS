//
//  OAIconTextDividerSwitchCell.mm
//  OsmAnd
//
//  Created by Skalii on 02.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAIconTextDividerSwitchCell.h"


@implementation OAIconTextDividerSwitchCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.dividerView.layer setCornerRadius:0.5f];
}

- (void)updateConstraints
{
    BOOL hasImage = self.iconView.image != nil;

    self.textLeftConstraint.active = hasImage;
    self.textLeftConstraintNoImage.active = !hasImage;
    self.textRightConstraint.active = !self.dividerView.hidden;
    self.textRightConstraintNoDivider.active = self.dividerView.hidden;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.iconView.image != nil;

        res = res || self.textLeftConstraint.active != hasImage;
        res = res || self.textLeftConstraintNoImage.active != !hasImage;
        res = res || self.textRightConstraint.active != !self.dividerView.hidden;
        res = res || self.textRightConstraintNoDivider.active != self.dividerView.hidden;
    }
    return res;
}

@end
