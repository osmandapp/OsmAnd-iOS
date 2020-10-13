//
//  OASettingsTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsTableViewCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 48.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OASettingsTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    if ([self isDirectionRTL])
    {
        self.descriptionView.textAlignment = NSTextAlignmentLeft;
        self.iconView.image = self.iconView.image.imageFlippedForRightToLeftLayoutDirection;
    }
    else
    {
        self.descriptionView.textAlignment = NSTextAlignmentRight;
    }
}

@end
