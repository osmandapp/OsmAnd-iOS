//
//  OACollapsableCoordinatesView.m
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableCoordinatesView.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OALocationConvert.h"
#import "OAPointDescription.h"
#import "OACustomButton.h"

#define kButtonHeight 32.0
#define kDefaultZoomOnShow 16.0f

@interface OACollapsableCoordinatesView () <OACustomButtonDelegate>

@end

@implementation OACollapsableCoordinatesView
{
    NSArray<OACustomButton *> *_buttons;
    NSInteger _selectedButtonIndex;

    UILabel *_viewLabel;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _lat = 0;
        _lon = 0;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame lat:(double)lat lon:(double)lon
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _lat = lat;
        _lon = lon;
        NSDictionary<NSNumber *, NSString*> *values = [OAPointDescription getLocationData:lat lon:lon];
        [self setData:values];
    }
    return self;
}

-(void) setData:(NSDictionary<NSNumber *,NSString *> *)data
{
    _coordinates = data;
    [self buildViews];
}

- (void) buildViews
{
    _viewLabel = [[UILabel alloc] initWithFrame:CGRectMake(kMarginLeft, 5.0, 100, 20)];
    _viewLabel.numberOfLines = 0;
    _viewLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _viewLabel.font = [UIFont systemFontOfSize:13.0];
    _viewLabel.textColor = UIColorFromRGB(color_text_footer);
    _viewLabel.backgroundColor = [UIColor clearColor];
    _viewLabel.text = OALocalizedString(@"coordinates_copy_descr");
    
    [self addSubview:_viewLabel];
    
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.coordinates.count];
    int i = 0;
    for (NSNumber *format in _coordinates.allKeys)
    {
        OACustomButton *btn = [OACustomButton buttonWithType:UIButtonTypeSystem];
        NSString *coord;
        if (format.integerValue == FORMAT_UTM)
            coord = [NSString stringWithFormat:@"UTM: %@", _coordinates[format]];
        else if (format.integerValue == FORMAT_OLC)
            coord = [NSString stringWithFormat:@"OLC: %@", _coordinates[format]];
        else if (format.integerValue == FORMAT_MGRS)
            coord = [NSString stringWithFormat:@"MGRS: %@", _coordinates[format]];
        else
            coord = _coordinates[format];
        
        [btn setTitle:coord forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
        btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        btn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
        btn.layer.cornerRadius = 4.0;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 0.8;
        btn.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
        btn.tintColor = UIColorFromRGB(color_primary_purple);
        btn.tag = i++;
        [btn setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(color_coordinates_background)] forState:UIControlStateHighlighted];
        btn.delegate = self;

        [self addSubview:btn];
        [buttons addObject:btn];
    }
    _buttons = [NSArray arrayWithArray:buttons];
}

- (void) updateButton
{
    
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 0;
    CGFloat viewHeight = 0;
    
    CGSize labelSize = [OAUtilities calculateTextBounds:_viewLabel.text width:width - 65.0 - 10.0 - 10.0 font:_viewLabel.font];
    _viewLabel.frame = CGRectMake(kMarginLeft, 5.0, labelSize.width, labelSize.height);
    
    viewHeight += labelSize.height + 10.0;
    y += viewHeight;
    
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
    if (_buttons.count > tag)
    {
        OACustomButton *button = _buttons[tag];
        [UIView animateWithDuration:0.3 animations:^{
            button.layer.backgroundColor = UIColorFromRGB(color_coordinates_background).CGColor;
            button.layer.borderColor = UIColor.clearColor.CGColor;
            button.tintColor = UIColor.whiteColor;
        }                completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2 animations:^{
                button.layer.backgroundColor = UIColor.clearColor.CGColor;
                button.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
                button.tintColor = UIColorFromRGB(color_primary_purple);
                [self showMenu:tag];
            }];
        }];
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    [self showMenu:tag];
}

@end
