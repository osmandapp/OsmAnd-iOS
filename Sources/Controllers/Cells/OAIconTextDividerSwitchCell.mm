//
//  OAIconTextDividerSwitchCell.mm
//  OsmAnd
//
//  Created by Skalii on 02.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAIconTextDividerSwitchCell.h"

@implementation OAIconTextDividerSwitchCell
{
    BOOL _showIcon;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.dividerView.layer setCornerRadius:0.5f];
}

- (void)updateConstraints
{
    self.textLeftConstraint.active = _showIcon;
    self.textLeftConstraintNoImage.active = !_showIcon;
    self.textRightConstraint.active = !self.dividerView.hidden;
    self.textRightConstraintNoDivider.active = self.dividerView.hidden;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        res = res || self.textLeftConstraint.active != _showIcon;
        res = res || self.textLeftConstraintNoImage.active != !_showIcon;
        res = res || self.textRightConstraint.active != !self.dividerView.hidden;
        res = res || self.textRightConstraintNoDivider.active != self.dividerView.hidden;
    }
    return res;
}

- (void)showIcon:(BOOL)show
{
    _showIcon = show;
}

@end
