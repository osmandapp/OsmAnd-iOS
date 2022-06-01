//
//  OASymbolMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAColors.h"

#import <OsmAndCore/TextRasterizer.h>

const static float kTextSize = 13.0f;

@interface OASymbolMapLayer()

@property (nonatomic) BOOL showCaptions;
@property (nonatomic) OsmAnd::TextRasterizer::Style captionStyle;
@property (nonatomic) double captionTopSpace;

@end

@implementation OASymbolMapLayer

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController];
    if (self)
    {
        _baseOrder = baseOrder;
    }
    return self;
}

- (void) initLayer
{
    [super initLayer];
    
    _captionTopSpace = 2 * self.displayDensityFactor;
    [self updateCaptionStyle];
}

- (BOOL) updateLayer
{
    [super updateLayer];
    
    [self updateCaptionStyle];
    
    return YES;
}

- (void) updateCaptionStyle
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    _showCaptions = settings.mapSettingShowPoiLabel.get;
    float textSize = settings.textSize.get;
    
    _captionStyle
        .setWrapWidth(20)
        .setMaxLines(3)
        .setBold(false)
        .setItalic(false)
        .setColor(OsmAnd::ColorARGB(self.nightMode ? color_widgettext_night_argb : color_widgettext_day_argb))
        .setSize(textSize * kTextSize * self.displayDensityFactor)
        .setHaloColor(OsmAnd::ColorARGB(self.nightMode ? color_widgettext_shadow_night_argb : color_widgettext_shadow_day_argb))
        .setHaloRadius(5);
}

@end
