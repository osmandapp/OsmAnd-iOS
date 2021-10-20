//
//  OASelectionIconTitleCollapsableWithIconCell.mm
//  OsmAnd
//
//  Created by Skalii on 19.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASelectionIconTitleCollapsableWithIconCell.h"
#import "OAColors.h"

@implementation OASelectionIconTitleCollapsableWithIconCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.selectionButtonContainer.layer.cornerRadius = 10.75;
    self.selectionButtonContainer.layer.borderWidth = 1.5;
    self.selectionButtonContainer.layer.borderColor = UIColorFromRGB(color_checkbox_outline).CGColor;

    self.checkboxHeightContainer.constant = 21.5;
    self.checkboxWidthContainer.constant = 21.5;
}

- (void)updateConstraints
{
    BOOL hasRightIcon = !self.rightIconView.hidden;
    BOOL isSelectable = !self.selectionButton.hidden;

    self.arrowIconWithRightIconConstraint.active = hasRightIcon;
    self.arrowIconNoRightIconConstraint.active = !hasRightIcon;

    self.openCloseGroupButtonWithRightIconConstraint.active = hasRightIcon;
    self.openCloseGroupButtonNoRightIconConstraint.active = !hasRightIcon;

    self.leftIconWithSelectionButtonConstraint.active = isSelectable;
    self.leftIconWithSelectionGroupButtonConstraint.active = isSelectable;
    self.leftIconNoSelectionButtonConstraint.active = !isSelectable;

    self.openCloseGroupButtonWithSelectionGroupButtonConstraint.active = isSelectable;
    self.openCloseGroupButtonNoSelectionGroupButtonConstraint.active = !isSelectable;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasRightIcon = !self.rightIconView.hidden;
        BOOL isSelectable = !self.selectionButton.hidden;

        res = res || self.arrowIconWithRightIconConstraint.active != hasRightIcon;
        res = res || self.arrowIconNoRightIconConstraint.active != !hasRightIcon;

        res = res || self.openCloseGroupButtonWithRightIconConstraint.active != hasRightIcon;
        res = res || self.openCloseGroupButtonNoRightIconConstraint.active != !hasRightIcon;

        res = res || self.leftIconWithSelectionButtonConstraint.active != isSelectable;
        res = res || self.leftIconWithSelectionGroupButtonConstraint.active != !isSelectable;
        res = res || self.leftIconNoSelectionButtonConstraint.active != !isSelectable;

        res = res || self.openCloseGroupButtonWithSelectionGroupButtonConstraint.active != isSelectable;
        res = res || self.openCloseGroupButtonNoSelectionGroupButtonConstraint.active != !isSelectable;
    }
    return res;
}

- (void)showRightIcon:(BOOL)show
{
    self.rightIconView.hidden = !show;
    self.dividerView.hidden = !show;
}

- (void)makeSelectable:(BOOL)selectable
{
    self.selectionButtonContainer.hidden = !selectable;
    self.selectionButton.hidden = !selectable;
    self.selectionGroupButton.hidden = !selectable;
}

@end
