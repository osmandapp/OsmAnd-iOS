//
//  OATwoButtonsTableViewCell.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 24.01.2023.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATwoButtonsTableViewCell.h"

@implementation OATwoButtonsTableViewCell

- (void)buttonsVisibility:(BOOL)show
{
    self.leftButton.hidden = !show;
    self.rightButton.hidden = !show;
    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.leftButton.hidden && !self.rightButton.hidden;
}

@end
