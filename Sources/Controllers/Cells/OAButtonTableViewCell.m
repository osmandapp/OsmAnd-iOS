//
//  OAButtonTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAButtonTableViewCell.h"

@implementation OAButtonTableViewCell

- (void)buttonVisibility:(BOOL)show
{
    self.button.hidden = !show;
    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.leftIconView.hidden || !self.button.hidden;
}

@end
