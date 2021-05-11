//
//  OAIconTextDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIconTextDescCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 50.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OAIconTextDescCell

+ (NSString *) getCellIdentifier
{
    return @"OAIconTextDescCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.arrowIconView.image = self.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;
}

- (void) updateConstraints
{
    BOOL hasImage = self.iconView.image != nil;

    self.textLeftMargin.active = hasImage;
    self.textLeftMarginNoImage.active = !hasImage;

    self.descrLeftMargin.active = hasImage;
    self.descrLeftMarginNoImage.active = !hasImage;

    self.textHeightPrimary.active = self.descView.hidden;
    self.textHeightSecondary.active = !self.descView.hidden;
    self.descrTopMargin.active = !self.descView.hidden;
    self.textBottomMargin.active = self.descView.hidden;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.iconView.image != nil;

        res = res || self.textLeftMargin.active != hasImage;
        res = res || self.textLeftMarginNoImage.active != !hasImage;

        res = res || self.descrLeftMargin.active != hasImage;
        res = res || self.descrLeftMarginNoImage.active != !hasImage;

        res = res || self.textHeightPrimary.active != self.descView.hidden;
        res = res || self.textHeightSecondary.active != !self.descView.hidden;
        res = res || self.descrTopMargin.active != !self.descView.hidden;
        res = res || self.textBottomMargin.active != self.descView.hidden;
    }
    return res;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
