//
//  OARouteStatisticsModeCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteStatisticsModeCell.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OARouteStatisticsModeCell ()

@property (weak, nonatomic) IBOutlet UIView *dividerView;

@end

@implementation OARouteStatisticsModeCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.dividerView.backgroundColor = [UIColor adaptiveSeparator];
    // Initialization code
    self.contentContainer.layer.cornerRadius = 9.;
    self.contentContainer.layer.borderWidth = 1.;
    self.contentContainer.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;

    self.modeButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.rightModeButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        self.contentContainer.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
}

@end
