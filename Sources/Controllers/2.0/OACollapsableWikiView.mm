//
//  OACollapsableWikiView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableWikiView.h"
#import "OAPOI.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OACommonTypes.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define kButtonHeight 36.0
#define kDefaultZoomOnShow 16.0f

@implementation OACollapsableWikiView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // init
    }
    return self;
}

-(void)setNearestWiki:(NSArray *)nearestWiki
{
    _nearestWiki = nearestWiki;
    [self buildButtons];
}

- (void)buildButtons
{
    CGFloat viewWidth = self.frame.size.width;
    int i = 0;
    for (OAPOI *w in self.nearestWiki)
    {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(50.0, i * kButtonHeight, viewWidth - 60.0, kButtonHeight);
        [btn setTitle:w.nameLocalized forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        btn.tag = i++;
        [btn addTarget:self action:@selector(btnPress:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
}

- (void)btnPress:(id)sender
{
    UIButton *btn = sender;
    NSInteger index = btn.tag;
    if (index >= 0 && index < self.nearestWiki.count)
    {
        OAPOI *w = self.nearestWiki[index];
        if (w)
            [self goToPoint:w];
    }
}

- (void)goToPoint:(OAPOI *)poi
{
    const OsmAnd::LatLon latLon(poi.latitude, poi.longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultZoomOnShow animated:YES];
    [mapVC showContextPinMarker:poi.latitude longitude:poi.longitude animated:NO];
    
    CGPoint touchPoint = CGPointMake(mapRendererView.bounds.size.width / 2.0, mapRendererView.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;
    
    OAMapSymbol *symbol = [OAMapViewController getMapSymbol:poi];
    symbol.touchPoint = CGPointMake(touchPoint.x, touchPoint.y);
    symbol.centerMap = YES;
    [OAMapViewController postTargetNotification:symbol];
}

- (void)adjustHeightForWidth:(CGFloat)width
{
    CGFloat viewHeight = self.nearestWiki.count * kButtonHeight + 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

@end
