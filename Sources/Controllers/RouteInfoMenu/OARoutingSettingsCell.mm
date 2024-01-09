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
#import "OAVoiceRouter.h"
#import "OARoutingHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

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
    
    [_optionsButton setTitle:OALocalizedString(@"shared_string_settings") forState:UIControlStateNormal];
    _optionsButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    _soundButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    
    [self setupButton:_optionsButton];
    [self setupButton:_soundButton];
    [self refreshSoundButton];
    [self adjustButtonsSize];
}

- (void) setupButton:(UIButton *)btn
{
    btn.layer.cornerRadius = 6.;
    btn.layer.borderWidth = 1.;
    btn.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
}
- (void) layoutSubviews
{
    [super layoutSubviews];

    _divider.frame = CGRectMake(0.0, self.contentView.frame.size.height - 0.5, self.contentView.frame.size.width, 0.5);
    [self refreshSoundButton];
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        [self setupButton:_optionsButton];
        [self setupButton:_soundButton];
    }
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) adjustInsets:(UIButton *)btn
{
    if ([btn isDirectionRTL])
    {
       btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
       btn.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 7);
       btn.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 4);
    }
    else
    {
       btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
       btn.contentEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 0);
       btn.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    }
}

- (void) adjustButtonsSize
{
    CGFloat soundTextWidth = [OAUtilities calculateTextBounds:_soundButton.currentTitle width:self.frame.size.width font:_soundButton.titleLabel.font].width;
    CGFloat soundBtnWidth = 55. + soundTextWidth;
    _soundButton.frame = CGRectMake(self.frame.size.width - 16. - soundBtnWidth - OAUtilities.getLeftMargin, 9., soundBtnWidth, 32.);
    CGFloat settingTextWidth = [OAUtilities calculateTextBounds: _optionsButton.currentTitle width:self.frame.size.width font:_optionsButton.titleLabel.font].width;
    CGFloat optionsBtnWidht = 55. + settingTextWidth;
    _optionsButton.frame = CGRectMake(16., 9., optionsBtnWidht, 32.);
    [self adjustInsets:_soundButton];
    [self adjustInsets:_optionsButton];
}

- (void) refreshSoundButton
{
    BOOL isMuted = [[OAAppSettings sharedManager].voiceMute get:[OARoutingHelper sharedInstance].getAppMode];
    [_soundButton setImage:isMuted ? [UIImage imageNamed:@"ic_custom_sound_off"] : [UIImage imageNamed:@"ic_custom_sound"]forState:UIControlStateNormal];
    [_soundButton setTitle:isMuted ? OALocalizedString(@"shared_string_off") : OALocalizedString(@"shared_string_on") forState:UIControlStateNormal];
    [self adjustButtonsSize];
}

- (IBAction)optionsButtonPressed:(id)sender
{
    [[OARootViewController instance].mapPanel showRoutePreferences];
    [self.delegate onOptionsButtonPressed];
}

- (IBAction)soundButtonPressed:(id)sender
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAApplicationMode *am = [OARoutingHelper sharedInstance].getAppMode;
    [[OARoutingHelper sharedInstance].getVoiceRouter setMute:![settings.voiceMute get:am] mode:am];
    [self refreshSoundButton];
}

@end
