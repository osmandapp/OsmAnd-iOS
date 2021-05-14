//
//  OATitleDescrDraggableCell.m
//  OsmAnd
//
//  Created by Paul on 18/04/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATitleDescrDraggableCell.h"

@implementation OATitleDescrDraggableCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)showImage:(BOOL)show
{
    _iconView.hidden = !show;
    
    _titleToMarginConstraint.active = !show;
    _titleToIconConstraint.active = show;
    
    _descrToMarginConstraint.active = !show;
    _descrToIconConstraint.active = show;
    
    [self updateConstraintsIfNeeded];
}

- (void) updateConstraints
{
    BOOL hasImage = !self.iconView.hidden;

    self.titleToIconConstraint.active = hasImage;
    self.titleToMarginConstraint.active = !hasImage;

    self.descrToIconConstraint.active = hasImage;
    self.descrToMarginConstraint.active = !hasImage;

    self.textHeightPrimary.active = self.descView.hidden;
    self.textHeightSecondary.active = !self.descView.hidden;
    
    self.titleBottomToCenter.active = self.descView.hidden;

    self.descrBottomConstraintPrimary.active = !self.descView.hidden && self.frame.size.height < 66;
    self.descrBottomConstraintSecondary.active = !self.descView.hidden && self.frame.size.height >= 66;

    self.titleTopConstraintPrimary.active = self.frame.size.height < 66;
    self.titleTopConstraintSecondary.active = self.frame.size.height >= 66;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = !self.iconView.hidden;;

        res = res || self.titleToIconConstraint.active != hasImage;
        res = res || self.titleToMarginConstraint.active != !hasImage;

        res = res || self.descrToIconConstraint.active != hasImage;
        res = res || self.descrToMarginConstraint.active != !hasImage;

        res = res || self.textHeightPrimary.active != self.descView.hidden;
        res = res || self.textHeightSecondary.active != !self.descView.hidden;
        res = res || self.titleBottomToCenter.active != self.descView.hidden;

        res = res || self.descrBottomConstraintPrimary.active != !self.descView.hidden && self.frame.size.height < 66;
        res = res || self.descrBottomConstraintSecondary.active != !self.descView.hidden && self.frame.size.height >= 66;

        res = res || self.titleTopConstraintPrimary.active != self.frame.size.height < 66;
        res = res || self.titleTopConstraintSecondary.active != self.frame.size.height >= 66;
    }
    return res;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.overflowButton setHidden:editing];
    [super setEditing:editing animated:animated];
}

@end
