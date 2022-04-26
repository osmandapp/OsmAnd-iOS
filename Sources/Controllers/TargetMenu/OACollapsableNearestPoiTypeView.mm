//
//  OACollapsableNearestPoiTypeView.m
//  OsmAnd Maps
//
//  Created by nnngrach on 17.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACollapsableNearestPoiTypeView.h"
#import "OAPOI.h"
#import "OARootViewController.h"
#import "OAPOILayer.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"

#define kButtonHeight 36.0
#define kDefaultZoomOnShow 16.0f

@interface OACollapsableNearestPoiTypeView () <OACustomButtonDelegate>

@end

@implementation OACollapsableNearestPoiTypeView
{
    NSArray<OAPOIType *> *_poiTypes;
    NSArray<OACustomButton *> *_buttons;
    NSInteger _selectedButtonIndex;
    double _latitude;
    double _longitude;
    BOOL _isPoiAdditional;
}

- (void)setData:(NSArray<OAPOIType *> *)poiTypes lat:(double)lat lon:(double)lon isPoiAdditional:(BOOL)isPoiAdditional
{
    _poiTypes = poiTypes;
    _latitude = lat;
    _longitude = lon;
    _isPoiAdditional = isPoiAdditional;
    [self buildViews];
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:_poiTypes.count];
    int i = 0;
    for (OAPOIType *poiType in _poiTypes)
    {
        NSString *title = poiType.nameLocalized;
        OACustomButton *btn = [self createButton:title];
        btn.tag = i++;
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    _buttons = [NSArray arrayWithArray:buttons];
}

- (OACustomButton *)createButton:(NSString *)title
{
    OACustomButton *btn = [OACustomButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
    btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    btn.layer.cornerRadius = 4.0;
    btn.layer.masksToBounds = YES;
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = UIColorFromRGB(0xe6e6e6).CGColor;
    [btn setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(0xfafafa)] forState:UIControlStateNormal];
    btn.tintColor = UIColorFromRGB(0x1b79f8);
    btn.delegate = self;
    return btn;
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 0;
    CGFloat viewHeight = 0;
    int i = 0;
    for (OACustomButton *btn in _buttons)
    {
        if (i > 0)
        {
            y += kButtonHeight + 10.0;
            viewHeight += 10.0;
        }
        
        btn.frame = CGRectMake(kMarginLeft, y, width - kMarginLeft - kMarginRight, kButtonHeight);
        viewHeight += kButtonHeight;
        i++;
    }
    
    viewHeight += 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

- (void) showQuickSearch:(OAPOIUIFilter *)filter
{
    [[OARootViewController instance].mapPanel hideContextMenu];
    [[OARootViewController instance].mapPanel openSearch:filter location:[[CLLocation alloc] initWithLatitude:_latitude longitude:_longitude]];
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return [sender isKindOfClass:UIMenuController.class] && action == @selector(copy:);
}

- (void)copy:(id)sender
{
    if (_buttons.count > _selectedButtonIndex)
    {
        OACustomButton *button = _buttons[_selectedButtonIndex];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:button.titleLabel.text];
    }
}

- (void)showMenu:(NSInteger)index
{
    _selectedButtonIndex = index;
    if (_buttons.count > _selectedButtonIndex)
    {
        OACustomButton *button = _buttons[_selectedButtonIndex];
        [self becomeFirstResponder];
        UIMenuController *menuController = UIMenuController.sharedMenuController;
        if (@available(iOS 13.0, *))
        {
            [menuController hideMenu];
            [menuController showMenuFromView:button rect:button.bounds];
        }
        else
        {
            [menuController setMenuVisible:NO animated:YES];
            [menuController setTargetRect:button.bounds inView:button];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    if (_poiTypes.count > tag)
    {
        OAPOIType *pointType = _poiTypes[tag];
        if (pointType)
        {
            OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getFilterById:[NSString stringWithFormat:@"%@%@", STD_PREFIX, pointType.name]];
            if (filter)
            {
                [filter clearFilter];
                if (_isPoiAdditional)
                {
                    [filter setTypeToAccept:pointType.category b:YES];
                    [filter updateTypesToAccept:pointType];
                    [filter setFilterByName:[pointType.name stringByReplacingOccurrencesOfString:@"_" withString:@":"].lowerCase];
                }
                else
                {
                    NSMutableSet<NSString *> *accept = [NSMutableSet new];
                    [accept addObject:pointType.name];
                    [filter selectSubTypesToAccept:pointType.category accept:accept];
                }

                [self showQuickSearch:filter];
            }
        }
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    [self showMenu:tag];
}

@end

