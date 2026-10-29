//
//  OAInputTableViewCell.m
//  OsmAnd
//
//  Created by Skalii on 20.12.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAInputTableViewCell.h"
#import "OAColors.h"
#import "GeneratedAssetSymbols.h"

@interface OAInputTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *clearButtonContainer;

@end

@implementation OAInputTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self.clearButton setImage:[UIImage templateImageNamed:ACImageNameIcBannerClose] forState:UIControlStateNormal];
    self.clearButton.tintColor = UIColorFromRGB(color_tint_gray);
}

- (void)clearButtonVisibility:(BOOL)show
{
    self.clearButtonContainer.hidden = !show;
}

- (void)inputFieldVisibility:(BOOL)show
{
    self.inputField.hidden = !show;
    if (!show)
        [self clearButtonVisibility:NO];

    [self updateMargins];
}

- (BOOL)checkSubviewsToUpdateMargins
{
    return !self.inputField.hidden;
}

@end
