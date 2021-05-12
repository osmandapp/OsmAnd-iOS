//
//  OAMultiIconTextDescCell.m
//  OsmAnd
//
//  Created by Paul on 18/04/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMultiIconTextDescCell.h"
#import "OAUtilities.h"

@implementation OAMultiIconTextDescCell
{
    BOOL _hideOverflowButton;
}

+ (NSString *)getCellIdentifier
{
    return @"OAMultiIconTextDescCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateConstraints
{
    self.descView.hidden = !self.descView.text || self.descView.text.length == 0;
    _descHeightPrimary.active = !self.descView.hidden;
    _descHeightSecondary.active = self.descView.hidden;
    _textHeightPrimary.active = !self.descView.hidden;
    _textHeightSecondary.active = self.descView.hidden;
    
    self.iconView.hidden = self.iconView.image == nil;
    _textLeftMarginNoIcon.active = self.iconView.hidden;
    _textLeftMargin.active = !self.iconView.hidden;
    
    self.overflowButton.hidden = _hideOverflowButton;
    _textRightMargin.active = !_hideOverflowButton;
    _textRightMarginNoButton.active = _hideOverflowButton;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.iconView.image != nil;
        
        res = res || self.textLeftMargin.active != hasImage;
        res = res || self.textLeftMarginNoIcon.active != !hasImage;

        res = res || self.textHeightPrimary.active != self.descView.hidden;
        res = res || self.textHeightSecondary.active != !self.descView.hidden;
        res = res || self.descHeightPrimary.active != self.descView.hidden;
        res = res || self.descHeightSecondary.active != !self.descView.hidden;
        
        res = res || self.textRightMargin.active != !_hideOverflowButton;
        res = res || self.textRightMarginNoButton.active != _hideOverflowButton;
    }
    return res;
}

- (void) setOverflowVisibility:(BOOL)hidden
{
    _hideOverflowButton = hidden;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.overflowButton setHidden:editing || _hideOverflowButton];
    [super setEditing:editing animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
