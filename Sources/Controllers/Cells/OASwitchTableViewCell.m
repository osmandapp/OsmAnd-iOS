//
//  OASwitchTableViewCell.m
//  OsmAnd Maps
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASwitchTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"

@interface OASwitchTableViewCell ()

@property (weak, nonatomic) IBOutlet UIStackView *rightContentStackView;

@property (weak, nonatomic) IBOutlet UIStackView *dividerStackView;

@end

@implementation OASwitchTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.dividerView.backgroundColor = [UIColor adaptiveSeparator];
}

- (void)dividerVisibility:(BOOL)show
{
    self.dividerStackView.hidden = !show;
}

- (void)switchVisibility:(BOOL)show
{
    self.rightContentStackView.hidden = !show;
    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.rightContentStackView.hidden;
}

@end
