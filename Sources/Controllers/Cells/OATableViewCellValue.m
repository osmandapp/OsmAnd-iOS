//
//  OATableViewCellValue.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableViewCellValue.h"

@interface OATableViewCellValue ()

@property (weak, nonatomic) IBOutlet UIStackView *valueStackView;

@end

@implementation OATableViewCellValue

- (void)valueVisibility:(BOOL)show
{
    self.valueStackView.hidden = !show;
    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.leftIconView.hidden || !self.valueStackView.hidden;
}

@end
