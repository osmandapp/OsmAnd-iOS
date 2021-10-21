//
//  OAPointWithRegionTableViewCell.mm
//  OsmAnd
//
//  Created by Skalii on 19.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAPointWithRegionTableViewCell.h"

@implementation OAPointWithRegionTableViewCell

- (void)updateConstraints
{
    BOOL hasLocation = !self.locationContainerView.hidden;
    BOOL hasDirection = !self.directionContainerView.hidden;
    BOOL hasRegion = !self.regionTextView.hidden;

    self.titleWithLocationConstraint.active = hasLocation;
    self.titleNoLocationConstraint.active = !hasLocation;

    self.regionWithDirectionConstraint.active = hasDirection;
    self.regionNoDirectionConstraint.active = !hasDirection;

    self.directionWithRegionConstraint.active = hasRegion;
    self.directionNoRegionConstraint.active = !hasRegion;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasLocation = !self.locationContainerView.hidden;
        BOOL hasDirection = !self.directionContainerView.hidden;
        BOOL hasRegion = !self.regionTextView.hidden;

        res = res || self.titleWithLocationConstraint.active != hasLocation;
        res = res || self.titleNoLocationConstraint.active != !hasLocation;

        res = res || self.regionWithDirectionConstraint.active != hasDirection;
        res = res || self.regionNoDirectionConstraint.active != !hasDirection;

        res = res || self.directionWithRegionConstraint.active != hasRegion;
        res = res || self.directionNoRegionConstraint.active != !hasRegion;
    }
    return res;
}

- (void)setDirection:(NSString *)direction
{
    BOOL hasDirection = direction && direction.length > 0;

    [self.directionTextView setText:direction];
    self.directionContainerView.hidden = !hasDirection;
    self.locationSeparatorView.hidden = !hasDirection || self.regionTextView.hidden;
    self.locationContainerView.hidden = !hasDirection && self.regionTextView.hidden;
}

- (void)setRegion:(NSString *)region
{
    BOOL hasRegion = region && region.length > 0;

    [self.regionTextView setText:region];
    self.regionTextView.hidden = !hasRegion;
    self.locationSeparatorView.hidden = !hasRegion || self.directionContainerView.hidden;
    self.locationContainerView.hidden = !hasRegion && self.directionContainerView.hidden;
}

@end
