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

@implementation OAAppModeView
{
    NSMutableArray<UIButton *> *_modeButtons;
    CALayer *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _modeButtons = [NSMutableArray array];
    [self setupModeButtons];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
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
    for (OAApplicationMode *mode in availableModes)
    {
        if (mode == [OAApplicationMode DEFAULT] && !_showDefault)
            continue;
        x += 12.;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(x, 0, w, h);
        [btn setImage:[UIImage imageNamed:mode.smallIconDark] forState:UIControlStateNormal];
        btn.contentMode = UIViewContentModeCenter;
        btn.tintColor = _selectedMode == mode ? UIColorFromRGB(color_chart_orange) : [UIColor darkGrayColor];
        btn.backgroundColor = _selectedMode == mode ? [btn.tintColor colorWithAlphaComponent:0.2] : UIColor.clearColor;
        btn.layer.cornerRadius = 4.;
        btn.tag = mode.modeId;
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
        btn.tintColor = _selectedMode.modeId == btn.tag ? UIColorFromRGB(color_chart_orange) : [UIColor darkGrayColor];
        btn.backgroundColor = _selectedMode.modeId == btn.tag ? [btn.tintColor colorWithAlphaComponent:0.2] : UIColor.clearColor;
    }
}

- (void) onButtonClick:(id)sender
{
    OAApplicationMode *mode = [OAApplicationMode getAppModeById:((UIButton *) sender).tag def:[OAApplicationMode DEFAULT]] ;
    self.selectedMode = mode;
    
    if (self.delegate)
        [self.delegate appModeChanged:mode];
    
    [self setupModeButtons];
}

@end
