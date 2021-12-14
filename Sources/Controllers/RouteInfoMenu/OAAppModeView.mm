//
//  OAAppModeView.m
//  OsmAnd
//
//  Created by Paul on 09/20/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAppModeView.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OARoutingHelper.h"

@implementation OAAppModeView
{
    NSMutableArray<UIButton *> *_modeButtons;
    CALayer *_divider;
    OAAutoObserverProxy *_routingModeChangedObserver;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _modeButtons = [NSMutableArray array];
    [self setupModeButtons];
    
    _routingModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onRoutingModeChanged:withKey:)
                                                                 andObserve:OARoutingHelper.sharedInstance.routingModeChangedObservable];
}

- (void) onRoutingModeChanged:(id)observable withKey:(id)key
{
    OAApplicationMode *newMode = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (newMode)
            [self setSelectedMode:newMode];
    });
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    if ([self isDirectionRTL])
        [self setTransform:CGAffineTransformMakeScale(-1, 1)];
}

- (void) setSelectedMode:(OAApplicationMode *)selectedMode
{
    OAApplicationMode *prevMode = _selectedMode;
    _selectedMode = selectedMode;
    
    if (_selectedMode != prevMode)
        [self updateSelection];
}

- (void) setShowDefault:(BOOL)showDefault
{
    if (_showDefault != showDefault)
    {
        _showDefault = showDefault;
        [self setupModeButtons];
    }
}

- (void) setupModeButtons
{
    if (_modeButtons)
    {
        for (UIButton *btn in _modeButtons)
            [btn removeFromSuperview];
        
        [_modeButtons removeAllObjects];
    }
    
    CGFloat x = 0.;
    CGFloat h = 36.0;
    CGFloat w = 48.0;
    NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
    for (NSInteger i = 0; i < availableModes.count; i++)
    {
        OAApplicationMode *mode = availableModes[i];
        if (mode == [OAApplicationMode DEFAULT] && !_showDefault)
            continue;
        
        x += 12.;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(x, 0, w, h);
        [btn setImage:mode.getIcon forState:UIControlStateNormal];
        btn.contentMode = UIViewContentModeCenter;
        btn.tintColor = UIColorFromRGB(mode.getIconColor);
        btn.backgroundColor = _selectedMode == mode ? [btn.tintColor colorWithAlphaComponent:0.2] : UIColor.clearColor;
        btn.layer.cornerRadius = 4.;
        btn.tag = i;
        [btn addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_modeButtons addObject:btn];
        [self.scrollView addSubview:btn];
        x += w;
    }
    self.scrollView.contentSize = CGSizeMake(x, self.scrollView.contentSize.height);
}

- (void) updateSelection
{
    for (UIButton *btn in _modeButtons)
    {
        NSInteger modeIndex = [self getAppModeIndex:_selectedMode];
        btn.tintColor = UIColorFromRGB(OAApplicationMode.values[btn.tag].getIconColor);
        btn.backgroundColor = modeIndex == btn.tag ? [btn.tintColor colorWithAlphaComponent:0.2] : UIColor.clearColor;
    }
}

- (void) onButtonClick:(id)sender
{
    OAApplicationMode *mode = [self getAppModeByIndex:((UIButton *) sender).tag] ;
    self.selectedMode = mode;
    
    if (self.delegate)
        [self.delegate appModeChanged:mode];
    
    [self setupModeButtons];
}

- (NSInteger) getAppModeIndex:(OAApplicationMode *)appMode
{
    return [[OAApplicationMode values] indexOfObject:appMode];
}

- (OAApplicationMode *) getAppModeByIndex:(NSInteger)index
{
    NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
    return index >= 0 && index < availableModes.count ? availableModes[index] : [OAApplicationMode DEFAULT];
}

@end
