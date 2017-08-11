//
//  OAAppModeCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAppModeCell.h"
#import "OAUtilities.h"

@implementation OAAppModeCell
{
    NSMutableArray<UIButton *> *_modeButtons;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) setSelectedMode:(OAMapVariantType)selectedMode
{
    OAMapVariantType prevMode = _selectedMode;
    _selectedMode = selectedMode;
    
    if (_selectedMode != prevMode)
        [self updateSelection];
}

- (void) setAvailableModes:(NSArray<NSString *> *)availableModes
{
    NSArray<NSString *> *prevModes = _availableModes;
    _availableModes = availableModes;
    
    if (![_availableModes isEqualToArray:prevModes])
        [self setupModeButtons];
}

- (void) setupModeButtons
{
    if (_modeButtons)
    {
        for (UIButton *btn in _modeButtons) {
            [btn removeFromSuperview];
        }
        [_modeButtons removeAllObjects];
    }
    
    CGFloat x = 0;
    CGFloat h = self.scrollView.bounds.size.height;
    CGFloat w = 50.0;
    for (NSString *mode in _availableModes) {
        OAMapVariantType m = [OAApplicationMode getVariantType:mode];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(x, 0, w, h);
        btn.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [btn setImage:[UIImage imageNamed:[OAApplicationMode getVariantTypeIconName:m]] forState:UIControlStateNormal];
        btn.tintColor = _selectedMode == m ? UIColorFromRGB(0xff8f00) : [UIColor darkGrayColor];
        btn.tag = m;
        [btn addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_modeButtons addObject:btn];
        [self.scrollView addSubview:btn];
        x += w;
    }
}

- (void) updateSelection
{
    for (UIButton *btn in _modeButtons) {
        btn.tintColor = _selectedMode == btn.tag ? UIColorFromRGB(0xff8f00) : [UIColor darkGrayColor];
    }
}

- (void) onButtonClick:(id)sender
{
    OAMapVariantType m = ((UIButton *) sender).tag;
    self.selectedMode = m;
    if (self.delegate)
        [self.delegate appModeChanged:m];
}

@end
