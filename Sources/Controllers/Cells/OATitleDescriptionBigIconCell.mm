//
//  OACardButtonCell.mm
//  OsmAnd
//
//  Created by Skalii on 30.05.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OATitleDescriptionBigIconCell.h"


@implementation OATitleDescriptionBigIconCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateConstraints
{
    BOOL hasDescription = !self.descriptionView.hidden;

    self.titleBottomMargin.active = hasDescription;
    self.titleVerticalConstraint.active = !hasDescription;
    self.titleBottomNoDescriptionMargin.active = !hasDescription;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionView.hidden;

        res = res || self.titleBottomMargin.active != hasDescription;
        res = res || self.titleVerticalConstraint.active != !hasDescription;
        res = res || self.titleBottomNoDescriptionMargin.active != !hasDescription;
    }
    return res;
}

- (void)showDescription:(BOOL)show
{
    self.descriptionView.hidden = !show;
}

@end
