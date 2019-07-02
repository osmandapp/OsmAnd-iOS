//
//  OACollapsableCoordinatesView.m
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableCoordinatesView.h"
#import "Localization.h"
#import "OACommonTypes.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAInAppCell.h"
#import "OAColors.h"

#define kButtonHeight 36.0
#define kDefaultZoomOnShow 16.0f

@implementation OACollapsableCoordinatesView
{
    NSArray<UIButton *> *_buttons;
    
    UILabel *_viewLabel;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // init
    }
    return self;
}

-(void) setData:(NSDictionary<NSString *,NSString *> *)data
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
    _viewLabel.textColor = UIColorFromRGB(text_color_osm_note_bottom_sheet);
    _viewLabel.backgroundColor = [UIColor clearColor];
    _viewLabel.text = OALocalizedString(@"coordinates_copy_descr");
    
    [self addSubview:_viewLabel];
    
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.coordinates.count];
    int i = 0;
    for (NSString *coord in _coordinates.allKeys)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:_coordinates[coord] forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
        btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        btn.layer.cornerRadius = 4.0;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 0.8;
        btn.layer.borderColor = UIColorFromRGB(0xe6e6e6).CGColor;
//        [btn setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(0xfafafa)] forState:UIControlStateNormal];
        btn.tintColor = UIColorFromRGB(bottomSheetPrimaryColor);
        btn.tag = i++;
        [btn addTarget:self action:@selector(btnPress:) forControlEvents:UIControlEventTouchUpInside];
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
    for (UIButton *btn in _buttons)
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

- (void) btnPress:(id)sender
{
    UIButton *btn = sender;
    NSInteger index = btn.tag;
    if (index >= 0 && index < self.coordinates.count)
    {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:self.coordinates.allValues[index]];
    }
}
- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

@end
