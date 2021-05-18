//
//  OAPreviewZoomLevelsCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPreviewZoomLevelsCell.h"

@implementation OAPreviewZoomLevelsCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self configureZoomPreviewView:self.minZoomPropertyView];
    [self configureZoomPreviewView:self.maxZoomPropertyView];
}

- (void) configureZoomPreviewView:(UIView *)view
{
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        view.backgroundColor = UIColor.clearColor;
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blurEffectView.layer.cornerRadius = 10.0;
        blurEffectView.layer.masksToBounds = YES;
        blurEffectView.frame = view.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [view insertSubview:blurEffectView atIndex:0];
    }
    else
    {
        view.layer.cornerRadius = 10.0;
        view.backgroundColor = UIColor.lightGrayColor;
    }
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (IBAction)minLevelZoomButtonTap:(id)sender
{
    if (self.delegate)
        [self.delegate toggleMinZoomPickerRow];
}

- (IBAction)maxLevelZoomButtonTap:(id)sender
{
    if (self.delegate)
    [self.delegate toggleMaxZoomPickerRow];
}

@end
