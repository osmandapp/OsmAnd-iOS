//
//  OACollapsableTransportStopRoutesView.m
//  OsmAnd
//
//  Created by Alexey on 13/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableTransportStopRoutesView.h"
#import "OATransportStopRoute.h"

@implementation OACollapsableTransportStopRoutesView
{
    NSArray<UIButton *> *_buttons;
}

- (void) setRoutes:(NSArray<OATransportStopRoute *> *)routes
{
    _routes = routes;
    [self buildViews];
}

- (void) buildViews
{
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.routes.count];
    int i = 0;
    for (OATransportStopRoute *route in self.routes)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:[route getDescription:YES] forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
        btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        btn.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
        btn.layer.cornerRadius = 4.0;
        btn.layer.masksToBounds = YES;
        btn.layer.borderWidth = 0.8;
        btn.tag = i++;
        //[btn addTarget:self action:@selector(btnPress:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
        [buttons addObject:btn];
    }
    _buttons = [NSArray arrayWithArray:buttons];
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 0;
    CGFloat viewHeight = 0;
        
    int i = 0;
    for (UIButton *btn in _buttons)
    {
        if (i > 0)
        {
            y += 36.0 + 10.0;
            viewHeight += 10.0;
        }
        
        btn.frame = CGRectMake(kMarginLeft, y, width - kMarginLeft - kMarginRight, 36.0);
        viewHeight += 36.0;
        i++;
    }
    
    viewHeight += 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

@end
