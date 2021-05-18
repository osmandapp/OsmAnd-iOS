//
//  OAIconTitleValueCell.m
//  OsmAnd
//
//  Created by Paul on 01.06.19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleValueCell.h"
#import "OAUtilities.h"

@implementation OAIconTitleValueCell
{
    BOOL _isImageShown;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([self.descriptionView isDirectionRTL])
    {
        self.descriptionView.textAlignment = NSTextAlignmentLeft;
        [self.iconView setImage:self.iconView.image.imageFlippedForRightToLeftLayoutDirection];
    }
    
    _isImageShown = YES;
}

-(void)showImage:(BOOL)show
{
    self.leftImageView.hidden = !show;
    self.imageTextLeadingMargin.active = show;
    self.noImageTextLeadingMargin.active = !show;
}

@end
