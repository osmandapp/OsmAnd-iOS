//
//  OAOverlayUnderlayView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAOverlayUnderlayView.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OAAppSettings.h"

@implementation OAOverlayUnderlayView
{
    OsmAndAppInstance _app;
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

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _lbOverlay.text = OALocalizedString(@"map_settings_over");
    _lbUnderlay.text = OALocalizedString(@"map_settings_under");
    self.layer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    self.layer.cornerRadius = 5.0;
    [self updateView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self doLayoutSubviews];
}

- (CGFloat)getHeight:(CGFloat)width
{
    if (_viewLayout == OAViewLayoutOverlayUnderlay && width < 400.0)
        return 81.0;
    else
        return 44.0;
}

-(BOOL)isTwoSlidersVisible
{
    return _viewLayout == OAViewLayoutOverlayUnderlay;
}

- (void)doLayoutSubviews
{
    CGRect f = self.frame;
    
    switch (_viewLayout)
    {
        case OAViewLayoutOverlayOnly:
            if (f.size.width < 250.0)
            {
                _lbOverlay.frame = CGRectMake(8.0, 0.0, 64.0, 21.0);
                _slOverlay.frame = CGRectMake(8.0, 7.0, f.size.width - 44.0, 31.0);
            }
            else
            {
                _lbOverlay.frame = CGRectMake(8.0, 11.0, 64.0, 21.0);
                _slOverlay.frame = CGRectMake(74.0, 7.0, f.size.width - 110.0, 31.0);
            }
            _lbUnderlay.hidden = YES;
            _slUnderlay.hidden = YES;
            _lbOverlay.hidden = NO;
            _slOverlay.hidden = NO;
            
            break;
            
        case OAViewLayoutUnderlayOnly:
            if (f.size.width < 250.0)
            {
                _lbUnderlay.frame = CGRectMake(8.0, 0.0, 64.0, 21.0);
                _slUnderlay.frame = CGRectMake(8.0, 7.0, f.size.width - 44.0, 31.0);
            }
            else
            {
                _lbUnderlay.frame = CGRectMake(8.0, 11.0, 64.0, 21.0);
                _slUnderlay.frame = CGRectMake(74.0, 7.0, f.size.width - 110.0, 31.0);
            }
            _lbOverlay.hidden = YES;
            _slOverlay.hidden = YES;
            _lbUnderlay.hidden = NO;
            _slUnderlay.hidden = NO;
            
            break;

        default:
            break;
    }
    
    if (f.size.width < 400.0)
    {
        switch (_viewLayout)
        {
            case OAViewLayoutOverlayUnderlay:
                _lbOverlay.frame = CGRectMake(8.0, 0.0, 64.0, 21.0);
                _slOverlay.frame = CGRectMake(8.0, 7.0, f.size.width - 44.0, 31.0);
                _lbUnderlay.frame = CGRectMake(8.0, 37.0, 64.0, 21.0);
                _slUnderlay.frame = CGRectMake(8.0, 44.0, f.size.width - 44.0, 31.0);
                _lbOverlay.hidden = NO;
                _slOverlay.hidden = NO;
                _lbUnderlay.hidden = NO;
                _slUnderlay.hidden = NO;
                
                break;
                
            default:
                break;
        }
    }
    else
    {
        switch (_viewLayout)
        {
            case OAViewLayoutOverlayUnderlay:
                _lbOverlay.frame = CGRectMake(8.0, 11.0, 64.0, 21.0);
                _slOverlay.frame = CGRectMake(74.0, 7.0, (f.size.width - 184.0) / 2.0, 31.0);
                _lbUnderlay.frame = CGRectMake(_slOverlay.frame.origin.x + _slOverlay.frame.size.width + 8.0, 11.0, 64.0, 21.0);
                _slUnderlay.frame = CGRectMake(_slOverlay.frame.origin.x + _slOverlay.frame.size.width + 74.0, 7.0, (f.size.width - 184.0) / 2.0, 31.0);
                _lbOverlay.hidden = NO;
                _slOverlay.hidden = NO;
                _lbUnderlay.hidden = NO;
                _slUnderlay.hidden = NO;
                
                break;
                
            default:
                break;
        }
    }
}

- (void)applyViewLayout
{
    BOOL shouldOverlaySliderBeVisible = _app.data.overlayMapSource && [[OAAppSettings sharedManager] getOverlayOpacitySliderVisibility];
    BOOL shouldUnderlaySliderBeVisible = _app.data.underlayMapSource && [[OAAppSettings sharedManager] getUnderlayOpacitySliderVisibility];
    
    if (shouldOverlaySliderBeVisible && shouldUnderlaySliderBeVisible)
        _viewLayout = OAViewLayoutOverlayUnderlay;
    else if (shouldUnderlaySliderBeVisible)
        _viewLayout = OAViewLayoutUnderlayOnly;
    else if (shouldOverlaySliderBeVisible)
        _viewLayout = OAViewLayoutOverlayOnly;
    else
        _viewLayout = OAViewLayoutNone;
}

- (void)updateView
{
    [self applyViewLayout];
    [self setNeedsLayout];
    _slOverlay.value = _app.data.overlayAlpha;
    _slUnderlay.value = _app.data.underlayAlpha;
}

- (IBAction)btnExitPressed:(id)sender
{
    [[OAAppSettings sharedManager] setOverlayOpacitySliderVisibility:NO];
    [[OAAppSettings sharedManager] setUnderlayOpacitySliderVisibility:NO];
    [self removeFromSuperview];
}

- (IBAction)slOverlayChanged:(id)sender
{
    UISlider *slider = sender;
    _app.data.overlayAlpha = slider.value;
}

- (IBAction)slUnderlayChanged:(id)sender
{
    UISlider *slider = sender;
    _app.data.underlayAlpha = slider.value;
}

@end
