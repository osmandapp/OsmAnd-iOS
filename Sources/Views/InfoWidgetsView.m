//
//  InfoWidgetsView.m
//  OsmAnd DVR
//
//  Created by Alexey Kulish on 15/04/15.
//
//

#import "InfoWidgetsView.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OASavingTrackHelper.h"

@implementation InfoWidgetsView
{
    UIButton *_btnSelect;
    
    UIFont *_primaryFont;
    UIFont *_unitsFont;

    UIColor *_primaryColor;
    UIColor *_unitsColor;
    
    OAAutoObserverProxy *_trackStartStopRecObserver;
    OAAutoObserverProxy *_trackRecordingObserver;
    
    BOOL _isRecording;
    BOOL _tick;
    
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASavingTrackHelper *_recHelper;
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
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _recHelper = [OASavingTrackHelper sharedInstance];
    
    CGFloat radius = 3.0;
    UIColor *widgetBackgroundColor = [UIColor whiteColor];
    self.viewGpxRecWidget.backgroundColor = [widgetBackgroundColor copy];
    self.viewGpxRecWidget.layer.cornerRadius = radius;

    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:2.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _btnSelect = [[UIButton alloc] initWithFrame:self.frame];
    _btnSelect.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_btnSelect addTarget:self action:@selector(btnSelectPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_btnSelect];

    _primaryFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:21];
    _unitsFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:14];
    
    _primaryColor = [UIColor blackColor];
    _unitsColor = [UIColor lightGrayColor];
    
    _isRecording = (_settings.mapSettingTrackRecordingGlobal || _settings.mapSettingTrackRecording);
    _tick = NO;
    [self updateGpxRec];
    
    _trackStartStopRecObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onTrackRecChanged)
                                                              andObserve:[_app trackStartStopRecObservable]];

    _trackRecordingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onTrackRecording)
                                                            andObserve:[_app trackRecordingObservable]];

}

-(void)dealloc
{
    if (_trackStartStopRecObserver)
    {
        [_trackStartStopRecObserver detach];
        _trackStartStopRecObserver = nil;
    }
    if (_trackRecordingObserver)
    {
        [_trackRecordingObserver detach];
        _trackRecordingObserver = nil;
    }
}

- (void)onTrackRecChanged
{
    _isRecording = (_settings.mapSettingTrackRecordingGlobal || _settings.mapSettingTrackRecording);
    _tick = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateGpxRec];
    });
}

- (void)onTrackRecording
{
    _tick = !_tick;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateGpxRec];
    });
}

-(void)btnSelectPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(infoSelectPressed)])
        [self.delegate infoSelectPressed];
}


- (void)updateGpxRec
{
    if ((_isRecording && !_tick) || !_isRecording)
        _iconGpxRecWidget.image = [UIImage imageNamed:@"widget_monitoring_rec_big_day.png"];
    else
        _iconGpxRecWidget.image = [UIImage imageNamed:@"widget_monitoring_rec_small_day.png"];
    
    if (_isRecording || [_recHelper hasData])
    {
        NSString *text = [_app getFormattedDistance:_recHelper.distance];
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
        
        NSUInteger spaceIndex = 0;
        for (NSUInteger i = text.length - 1; i > 0; i--)
            if ([text characterAtIndex:i] == ' ')
            {
                spaceIndex = i;
                break;
            }
        
        NSRange valueRange = NSMakeRange(0, spaceIndex);
        NSRange unitRange = NSMakeRange(spaceIndex, text.length - spaceIndex);
        
        [string addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
        [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
        [string addAttribute:NSForegroundColorAttributeName value:_unitsColor range:unitRange];
        [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
        
        _lbGpxRecWidget.attributedText = string;
    }
    else
    {
        NSString *text = @"REC";
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
        NSRange valueRange = NSMakeRange(0, text.length);
        [string addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
        [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
        _lbGpxRecWidget.attributedText = string;
    }
}

@end
