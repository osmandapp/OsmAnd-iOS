//
//  OARouteStatisticsModeCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteStatisticsModeCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OARouteStatisticsModeCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    self.contentContainer.layer.cornerRadius = 9.;
    self.contentContainer.layer.borderWidth = 1.;
    self.contentContainer.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
