//
//  OAFoldersCollectionViewCell.m
//  OsmAnd
//
//  Created by nnngrach on 0.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFoldersCollectionViewCell.h"

@implementation OAFoldersCollectionViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void)updateConstraints
{
    BOOL hasImage = !self.imageView.hidden;
    BOOL hasText = self.titleLabel.text.length > 0;
    
    if (hasImage && !hasText)
    {
        self.labelWithIconConstraint.active = NO;
        self.labelNoIconConstraint.active = NO;
        self.leftIconConstraint.priority = 1;
        self.centerAlignIconConstraint.priority = 1000;
    }
    else
    {
        self.labelWithIconConstraint.active = hasImage;
        self.labelNoIconConstraint.active = !hasImage;
        self.leftIconConstraint.priority = 1000;
        self.centerAlignIconConstraint.priority = 1;
    }

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = !self.imageView.hidden;

        res = res || self.labelWithIconConstraint.active != hasImage;
        res = res || self.labelNoIconConstraint.active != !hasImage;
    }
    return res;
}

- (void)showImage:(BOOL)show
{
    self.imageView.hidden = !show;
}

@end
