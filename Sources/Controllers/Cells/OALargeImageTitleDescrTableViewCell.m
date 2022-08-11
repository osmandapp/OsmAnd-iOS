//
//  OALargeImageTitleDescrTableViewCell.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OALargeImageTitleDescrTableViewCell.h"

@implementation OALargeImageTitleDescrTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateConstraints
{
    BOOL hasButton = !self.button.hidden;

    self.descriptionWithButtonConstraint.active = hasButton;
    self.descriptionNoButtonConstraint.active = !hasButton;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasButton = !self.button.hidden;

        res = res || self.descriptionWithButtonConstraint.active != hasButton;
        res = res || self.descriptionNoButtonConstraint.active != !hasButton;
    }
    return res;
}

- (void)showButton:(BOOL)show
{
    self.button.hidden = !show;
}

@end
