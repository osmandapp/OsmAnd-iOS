//
//  OASelectionCollapsableCell.mm
//  OsmAnd
//
//  Created by Skalii on 19.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASelectionCollapsableCell.h"
#import "OAColors.h"

@implementation OASelectionCollapsableCell

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
    BOOL hasOptionButton = !self.optionsButton.hidden;
    BOOL isSelectable = !self.selectionButton.hidden;

    self.arrowIconWithOptionButtonConstraint.active = hasOptionButton;
    self.arrowIconNoOptionButtonConstraint.active = !hasOptionButton;

    self.openCloseGroupButtonWithOptionsGroupButtonConstraint.active = hasOptionButton;
    self.openCloseGroupButtonNoOptionsGroupButtonConstraint.active = !hasOptionButton;

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
        BOOL hasOptinButton = !self.optionsButton.hidden;
        BOOL isSelectable = !self.selectionButton.hidden;

        res = res || self.arrowIconWithOptionButtonConstraint.active != hasOptinButton;
        res = res || self.arrowIconNoOptionButtonConstraint.active != !hasOptinButton;

        res = res || self.openCloseGroupButtonWithOptionsGroupButtonConstraint.active != hasOptinButton;
        res = res || self.openCloseGroupButtonNoOptionsGroupButtonConstraint.active != !hasOptinButton;

        res = res || self.leftIconWithSelectionButtonConstraint.active != isSelectable;
        res = res || self.leftIconWithSelectionGroupButtonConstraint.active != !isSelectable;
        res = res || self.leftIconNoSelectionButtonConstraint.active != !isSelectable;

        res = res || self.openCloseGroupButtonWithSelectionGroupButtonConstraint.active != isSelectable;
        res = res || self.openCloseGroupButtonNoSelectionGroupButtonConstraint.active != !isSelectable;
    }
    return res;
}

- (void)showOptionsButton:(BOOL)show
{
    self.optionsButton.hidden = !show;
    self.optionsGroupButton.hidden = !show;
    self.dividerView.hidden = !show;
}

- (void)makeSelectable:(BOOL)selectable
{
    self.selectionButtonContainer.hidden = !selectable;
    self.selectionButton.hidden = !selectable;
    self.selectionGroupButton.hidden = !selectable;
}

@end
