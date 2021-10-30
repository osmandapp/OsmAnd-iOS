//
//  OAQuadItemsWithTitleDescIconCell.mm
//  OsmAnd
//
//  Created by Skalii on 27.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAQuadItemsWithTitleDescIconCell.h"

@implementation OAQuadItemsWithTitleDescIconCell

- (void)updateConstraints
{
    BOOL hasBottomButtons = !self.bottomLeftView.hidden && !self.bottomRightView.hidden;

    self.topButtonsWithBottomButtonsConstraint.active = hasBottomButtons;
    self.topButtonsNoBottomButtonsConstraint.active = !hasBottomButtons;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasBottomButtons = !self.bottomLeftView.hidden && !self.bottomRightView.hidden;

        res = res || self.topButtonsWithBottomButtonsConstraint.active != hasBottomButtons;
        res = res || self.topButtonsNoBottomButtonsConstraint.active != !hasBottomButtons;
    }
    return res;
}

- (void)showBottomButtons:(BOOL)show
{
    self.separatorView.hidden = !show;
    self.bottomLeftView.hidden = !show;
    self.bottomRightView.hidden = !show;
}

@end
