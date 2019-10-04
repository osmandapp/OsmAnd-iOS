//
//  OARoutingSettingsCell.m
//  OsmAnd
//
//  Created by Paul on 02/10/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARoutingSettingsCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "Localization.h"

@implementation OARoutingSettingsCell
{
    CALayer *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    _divider = [CALayer layer];
    _divider.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    [self.contentView.layer addSublayer:_divider];
    
    [self setupButton:_optionsButton];
    [self setupButton:_soundButton];
    [self refreshSoundButton];
}

- (void) setupButton:(UIButton *)btn
{
    btn.layer.cornerRadius = 6.;
    btn.layer.borderWidth = 1.;
    btn.layer.borderColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    _divider.frame = CGRectMake(0.0, self.contentView.frame.size.height - 0.5, self.contentView.frame.size.width, 0.5);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}


- (void) refreshSoundButton
{
    BOOL isMuted = [OAAppSettings sharedManager].voiceMute;
    [_soundButton setImage:isMuted ? [UIImage imageNamed:@"ic_custom_sound"] : [UIImage imageNamed:@"ic_custom_sound_off"] forState:UIControlStateNormal];
}

- (IBAction)optionsButtonPressed:(id)sender
{
    [[OARootViewController instance].mapPanel showRoutePreferences];
}

- (IBAction)soundButtonPressed:(id)sender
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setVoiceMute:!settings.voiceMute];
    [self refreshSoundButton];
}

@end
