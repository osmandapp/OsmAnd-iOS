//
//  OAValueTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAValueTableViewCell.h"

@interface OAValueTableViewCell ()

@property (weak, nonatomic) IBOutlet UIStackView *valueStackView;

@end

@implementation OAValueTableViewCell

- (void)valueVisibility:(BOOL)show
{
    self.valueStackView.hidden = !show;
    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.valueStackView.hidden;
}

@end
