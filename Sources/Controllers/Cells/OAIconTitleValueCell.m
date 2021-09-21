//
//  OAIconTitleValueCell.m
//  OsmAnd
//
//  Created by Paul on 01.06.19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleValueCell.h"

@implementation OAIconTitleValueCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    if ([self.descriptionView isDirectionRTL])
    {
        self.descriptionView.textAlignment = NSTextAlignmentLeft;
        [self.rightIconView setImage:self.rightIconView.image.imageFlippedForRightToLeftLayoutDirection];
    }
}

-(void)showLeftIcon:(BOOL)show
{
    self.leftIconView.hidden = !show;
    self.leftIconTextLeadingMargin.active = show;
    self.noLeftIconTextLeadingMargin.active = !show;
}

-(void)showRightIcon:(BOOL)show
{
    self.rightIconView.hidden = !show;
    self.rightIconDescLeadingMargin.active = show;
    self.noRightIconDecsLeadingMargin.active = !show;
}

@end
