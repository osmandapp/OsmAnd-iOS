//
//  OAGpxStatBlockCollectionViewCell.mm
//  OsmAnd
//
//  Created by Skalii on 17.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAGpxStatBlockCollectionViewCell.h"

@implementation OAGpxStatBlockCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)updateConstraints
{
    BOOL hasSeparator = !self.separatorView.hidden;

    self.separatorConstraint.active = hasSeparator;
    self.noSeparatorConstraint.active = !hasSeparator;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasSeparator = !self.separatorView.hidden;

        res = res || self.separatorConstraint.active != hasSeparator;
        res = res || self.noSeparatorConstraint.active != !hasSeparator;
    }
    return res;
}

@end
