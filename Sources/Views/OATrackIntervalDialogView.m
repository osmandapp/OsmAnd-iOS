//
//  OATrackIntervalDialogView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATrackIntervalDialogView.h"
#import "OAAppSettings.h"
#import "Localization.h"

@implementation OATrackIntervalDialogView
{
    double delta;
    OAAppSettings *_settings;
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            [self commonInit];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    if ([bundle count])
    {
        self = [bundle firstObject];
        if (self) {
            self.frame = frame;
            [self commonInit];
        }
    }
    return self;
}

-(void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    int interval = [_settings.mapSettingSaveTrackIntervalGlobal get];
    int index = 0;
    for (int i = 0; i < _settings.trackIntervalArray.count; i++)
        if ([_settings.trackIntervalArray[i] intValue] == interval)
        {
            index = i;
            break;
        }
    delta = 1.0 / (_settings.trackIntervalArray.count - 1);
    _slInterval.value = index * delta;
    [self updateIntervalLabel:index];
    _lbRemember.text = OALocalizedString(@"track_interval_remember");
    _lbShowOnMap.text = OALocalizedString(@"map_settings_show");
    
    [_swShowOnMap setOn:_settings.mapSettingShowRecordingTrack];
}

- (void)updateInterval
{
    int i = [self getInterval];
    _slInterval.value = i * delta;
    [self updateIntervalLabel:i];
}

- (void)updateIntervalLabel:(int)interval
{
    NSString *prefix = [OALocalizedString(@"rec_interval") stringByAppendingString:@": "];
    
    NSString *text = [_settings getFormattedTrackInterval:[_settings.trackIntervalArray[interval] intValue]];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[prefix stringByAppendingString:text]];
    
    NSRange valueRange = NSMakeRange(0, prefix.length);
    NSRange unitRange = NSMakeRange(prefix.length, text.length);
    
    [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:valueRange];
    [string addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:unitRange];
    
    _lbInterval.attributedText = string;
}

- (int)getInterval
{
    float floatInterval = roundf(_slInterval.value / delta);
    int interval = (int)(floatInterval);
    if (interval < 0)
        interval = 0;
    else if (interval >= _settings.trackIntervalArray.count)
        interval = (int) _settings.trackIntervalArray.count - 1;
    return interval;
}

- (IBAction)onSliderChanged:(id)sender
{
    [self updateInterval];
}



@end
