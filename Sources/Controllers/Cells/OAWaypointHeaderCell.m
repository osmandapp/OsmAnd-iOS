//
//  OAWaypointHeader.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointHeaderCell.h"
#import "OAUtilities.h"

@implementation OAWaypointHeaderCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateLayout
{
    CGSize cellSize = self.bounds.size;
    CGFloat lx = 16;
    CGFloat rx = 0;
    if (!_progressView.hidden)
        lx += 20;
    
    if (!_textButton.hidden)
    {
        CGFloat w = [OAUtilities calculateTextBounds:@"" width:160 font:_textButton.titleLabel.font].width + 4;
        _textButton.frame = CGRectMake(cellSize.width - w, 0, w, cellSize.height);
        rx += w;
    }
    if (!_imageButton.hidden)
    {
        CGRect btnFrame = _imageButton.frame;
        _imageButton.center = CGPointMake(cellSize.width - rx - btnFrame.size.width / 2, _imageButton.center.y);
        rx += btnFrame.size.width;
    }
    if (_switchView.hidden)
    {
        CGRect swFrame = _switchView.frame;
        _switchView.center = CGPointMake(cellSize.width - rx - swFrame.size.width / 2, _switchView.center.y);
    }
    if (_titleView.hidden)
    {
        _titleView.frame = CGRectMake(lx, 0, cellSize.width - rx - lx, cellSize.height);
    }
}

@end
