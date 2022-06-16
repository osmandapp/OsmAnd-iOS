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
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OATargetInfoViewController.h"

#define kButtonHeight 36.0
#define kDefaultZoomOnShow 16.0f

@interface OACollapsableNearestPoiTypeView () <OAButtonDelegate>

@end

@implementation OACollapsableNearestPoiTypeView
{
    NSArray<OAPOIType *> *_poiTypes;
    OAPOI *_amenity;
    NSArray<OAButton *> *_buttons;
    NSInteger _selectedButtonIndex;
    double _latitude;
    double _longitude;
    BOOL _isPoiAdditional;
    NSString *_textRow;
    NSInteger _textRowButtonIndex;
}

- (void) setData:(NSArray<OAPOIType *> *)poiTypes
         amenity:(OAPOI *)amenity
             lat:(double)lat
             lon:(double)lon
 isPoiAdditional:(BOOL)isPoiAdditional
         textRow:(OARowInfo *)textRow
{
    _poiTypes = poiTypes;
    _amenity = amenity;
    _latitude = lat;
    _longitude = lon;
    _isPoiAdditional = isPoiAdditional;
    if (textRow)
        _textRow = [[textRow.textPrefix stringByAppendingString:@": "] stringByAppendingString:[textRow.text lowercaseString]];
    [self buildViews];
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:_poiTypes.count];
    int i = 0;
    for (OAPOIType *poiType in _poiTypes)
    {
        NSString *title = poiType.nameLocalized;
        OAButton *btn = [self createButton:title];
        btn.tag = i++;
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    if (_textRow && _textRow.length > 0)
    {
        _textRowButtonIndex = i;
        OAButton *btn = [self createButton:_textRow];
        btn.tag = _textRowButtonIndex;
        [btn setBackgroundImage:nil forState:UIControlStateNormal];
        btn.tintColor = UIColor.blackColor;
        btn.titleLabel.numberOfLines = 0;
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    else
    {
        _textRowButtonIndex = -1;
    }

    _buttons = buttons;
}

- (OAButton *)createButton:(NSString *)title
{
    OAButton *btn = [OAButton buttonWithType:UIButtonTypeSystem];
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
    for (OAButton *btn in _buttons)
    {
        if (i > 0)
        {
            y += kButtonHeight + 10.0;
            viewHeight += 10.0;
        }

        CGFloat height = kButtonHeight;
        if (btn.tag == _textRowButtonIndex)
        {
            height = [OAUtilities calculateTextBounds:btn.titleLabel.text
                                                width:width - kMarginLeft - kMarginRight
                                                font:btn.titleLabel.font].height;
            CGFloat lineHeight = ceil(btn.titleLabel.font.lineHeight);
            if (height > lineHeight)
            {
                CGFloat margins = kButtonHeight - lineHeight;
                height = height + margins;
            }
        }

        btn.frame = CGRectMake(kMarginLeft, y, width - kMarginLeft - kMarginRight, height);
        viewHeight += btn.frame.size.height;
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
        OAButton *button = _buttons[_selectedButtonIndex];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:button.titleLabel.text];
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    if (_poiTypes.count > tag && tag != _textRowButtonIndex && _amenity && _amenity.type && _amenity.type.category)
    {
        OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getFilterById:
                [NSString stringWithFormat:@"%@%@", STD_PREFIX, _amenity.type.category.name]];
        if (filter)
        {
            OAPOIType *pt = _poiTypes[tag];
            [filter clearFilter];
            if (_isPoiAdditional)
            {
                [filter setTypeToAccept:_amenity.type.category b:YES];
                [filter updateTypesToAccept:pt];
                [filter setFilterByName:[pt.name stringByReplacingOccurrencesOfString:@"_" withString:@":"].lowerCase];
            }
            else
            {
                NSMutableSet<NSString *> *accept = [NSMutableSet new];
                [accept addObject:pt.name];
                [filter selectSubTypesToAccept:_amenity.type.category accept:accept];
            }

             [self showQuickSearch:filter];
        }
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    _selectedButtonIndex = tag;
    if (_buttons.count > _selectedButtonIndex)
        [OAUtilities showMenuInView:self fromView:_buttons[_selectedButtonIndex]];
}

@end

