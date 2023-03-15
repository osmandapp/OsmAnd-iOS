//
//  OACardTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 23.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACardTableViewCell.h"
#import "OASizes.h"

@interface OACardTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *contentBackgroundTopMarginView;

@end

@implementation OACardTableViewCell

- (void)updateSeparatorInset
{
    self.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
}

- (void)topBackgroundMarginVisibility:(BOOL)show
{
    self.contentBackgroundTopMarginView.hidden = !show;
}

- (void)buttonVisibility:(BOOL)show
{
    self.button.hidden = !show;
    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.button.hidden;
}

@end
