//
//  OAAppModeCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAppModeCell.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAAutoObserverProxy.h"
#import "OAObservable.h"
#import "OARoutingHelper.h"

@implementation OAAppModeCell
{
    NSMutableArray<UIButton *> *_modeButtons;
    CALayer *_divider;
    OAAutoObserverProxy *_routingModeChangedObserver;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    _divider = [CALayer layer];
    _divider.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    [self.contentView.layer addSublayer:_divider];

    _modeButtons = [NSMutableArray array];
    [self setupModeButtons];
    
    _routingModeChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onRoutingModeChanged:withKey:)
                                                                 andObserve:OARoutingHelper.sharedInstance.routingModeChangedObservable];
}

- (void) dealloc
{
    if (_routingModeChangedObserver)
    {
        [_routingModeChangedObserver detach];
        _routingModeChangedObserver = nil;
    }
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

    _divider.frame = CGRectMake(0.0, self.contentView.frame.size.height - 0.5, self.contentView.frame.size.width, 0.5);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
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
    
    CGFloat x = 8;
    CGFloat h = self.scrollView.bounds.size.height;
    CGFloat w = 50.0;
    NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
    for (NSInteger i = 0; i < availableModes.count; i++)
    {
        OAApplicationMode *mode = availableModes[i];
        if (mode == [OAApplicationMode DEFAULT] && !_showDefault)
            continue;
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(x, 4.0, w, h - 8.0);
        btn.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [btn setImage:mode.getIcon forState:UIControlStateNormal];
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
