//
//  OACustomSelectionCollapsableCell.m
//  OsmAnd Maps
//
//  Created by Paul on 03.26.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACustomSelectionCollapsableCell.h"
#import "OAColors.h"

@implementation OACustomSelectionCollapsableCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _selectionButtonContainer.layer.cornerRadius = 10.75;
    _selectionButtonContainer.layer.borderWidth = 1.5;
    _selectionButtonContainer.layer.borderColor = UIColorFromRGB(color_checkbox_outline).CGColor;
    
    _checkboxHeightContainer.constant = 21.5;
    _checkboxWidthContainer.constant = 21.5;
}

- (void)updateConstraints
{
    BOOL hasDescription = !self.descriptionView.hidden;
    BOOL isSelectable = !self.selectionButton.hidden;

    self.textTopConstraint.active = hasDescription;
    self.textTopNoDescConstraint.active = !hasDescription;
    self.textBottomConstraint.active = hasDescription;
    self.textBottomNoDescConstraint.active = !hasDescription;
    self.textLeftConstraint.active = isSelectable;
    self.textLeftNoSelectConstraint.active = !isSelectable;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionView.hidden;
        BOOL isSelectable = !self.selectionButton.hidden;

        res = res || self.textTopConstraint.active != hasDescription;
        res = res || self.textTopNoDescConstraint.active != !hasDescription;
        res = res || self.textBottomConstraint.active != hasDescription;
        res = res || self.textBottomNoDescConstraint.active != !hasDescription;
        res = res || self.textLeftConstraint.active != isSelectable;
        res = res || self.textLeftNoSelectConstraint.active != !isSelectable;
    }
    return res;
}

- (void)makeSelectable:(BOOL)selectable
{
    self.selectionButtonContainer.hidden = !selectable;
    self.selectionButton.hidden = !selectable;
    self.selectionGroupButton.hidden = !selectable;
}

@end
