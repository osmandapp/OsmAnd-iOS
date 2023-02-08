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

    self.titleView.font = [UIFont scaledSystemFontOfSize:20. weight:UIFontWeightSemibold];
}

- (void) updateConstraints
{
    BOOL hasDescription = !self.descriptionView.hidden;
    BOOL hasLeftIcon = !self.leftIconView.hidden;
    BOOL hasRightIcon = !self.rightIconView.hidden;

    self.titleBottomMargin.active = hasDescription;
    self.titleVerticalConstraint.active = !hasDescription;
    self.titleBottomNoDescriptionMargin.active = !hasDescription;

    self.titleWithLeftIconConstraint.active = hasLeftIcon;
    self.titleNoLeftIconConstraint.active = !hasLeftIcon;
    self.titleWithRightIconConstraint.active = hasRightIcon;
    self.titleNoRightIconConstraint.active = !hasRightIcon;

    self.descriptionWithLeftIconConstraint.active = hasLeftIcon;
    self.descriptionNoLeftIconConstraint.active = !hasLeftIcon;
    self.descriptionWithRightIconConstraint.active = hasRightIcon;
    self.descriptionNoRightIconConstraint.active = !hasRightIcon;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasDescription = !self.descriptionView.hidden;
        BOOL hasLeftIcon = !self.leftIconView.hidden;
        BOOL hasRightIcon = !self.rightIconView.hidden;

        res = res || self.titleBottomMargin.active != hasDescription;
        res = res || self.titleVerticalConstraint.active != !hasDescription;
        res = res || self.titleBottomNoDescriptionMargin.active != !hasDescription;

        res = res || self.titleWithLeftIconConstraint.active != hasLeftIcon;
        res = res || self.titleNoLeftIconConstraint.active != !hasLeftIcon;
        res = res || self.titleWithRightIconConstraint.active != hasRightIcon;
        res = res || self.titleNoRightIconConstraint.active != !hasRightIcon;

        res = res || self.descriptionWithLeftIconConstraint.active != hasLeftIcon;
        res = res || self.descriptionNoLeftIconConstraint.active != !hasLeftIcon;
        res = res || self.descriptionWithRightIconConstraint.active != hasRightIcon;
        res = res || self.descriptionNoRightIconConstraint.active != !hasRightIcon;
    }
    return res;
}

- (void)showDescription:(BOOL)show
{
    self.descriptionView.hidden = !show;
}

- (void)showLeftIcon:(BOOL)show
{
    self.leftIconView.hidden = !show;
}

- (void)showRightIcon:(BOOL)show
{
    self.rightIconView.hidden = !show;
}

@end
