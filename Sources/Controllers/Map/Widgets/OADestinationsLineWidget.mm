//
//  OADestinationsLineWidget.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 21.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADestinationsLineWidget.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OALocationServices.h"
#import "OAMapRendererView.h"
#import "OAMapUtils.h"
#import "OADestinationLineDelegate.h"
#import "OADestinationsLayer.h"
#import "OADestinationsHelper.h"
#import "OAMapLayers.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/Map/MapMarkerBuilder.h>

#define kLabelOffset 15
#define kArrowOffset 80
#define kShadowRadius 22
#define kArrowFrame @"map_marker_direction_arrow_p1_light"
#define kArrowShadow @"map_marker_direction_arrow_p3_shadow"
#define kWidthCorrectionValue 10

@implementation OADestinationsLineWidget
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapViewController *_mapViewController;

    NSMutableArray<OADestination *> *_destinationsArray;
    CALayer *_destinationLineSublayer;

    OADestinationLineDelegate *_destinationLineDelegate;
    NSInteger _indexToMove;
    BOOL _isMoving;

    NSDictionary<NSString *, NSNumber *> *_lineAttrs;
    NSDictionary<UIColor *, NSString *> *_markerColors;
    BOOL _attrsChanged;

    std::shared_ptr<OsmAnd::MapMarker> _distanceMarker;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.frame = frame;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _destinationsArray = [[NSMutableArray alloc] init];

    [self updateAttributes];
    _markerColors = @{ UIColorFromRGB(marker_pin_color_orange) : @"map_marker_direction_arrow_p2_color_pin_1",
                       UIColorFromRGB(marker_pin_color_teal) : @"map_marker_direction_arrow_p2_color_pin_2",
                       UIColorFromRGB(marker_pin_color_green) : @"map_marker_direction_arrow_p2_color_pin_3",
                       UIColorFromRGB(marker_pin_color_red) : @"map_marker_direction_arrow_p2_color_pin_4",
                       UIColorFromRGB(marker_pin_color_light_green) : @"map_marker_direction_arrow_p2_color_pin_5",
                       UIColorFromRGB(marker_pin_color_purple) : @"map_marker_direction_arrow_p2_color_pin_6",
                       UIColorFromRGB(marker_pin_color_blue) : @"map_marker_direction_arrow_p2_color_pin_7" };
    
    self.hidden = NO;
    self.opaque = NO;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self initDestinationLayer];
}

- (void) moveMarker:(NSInteger)index
{
    if (_isMoving)
    {
        _isMoving = NO;
        _indexToMove = -1;
    }
    else
    {
        _isMoving = YES;
        _indexToMove = index;
    }
}

- (BOOL) updateAttributes
{
    NSDictionary<NSString *, NSNumber *> *lineAttrs = [_mapViewController getLineRenderingAttributes:@"measureDistanceLine"];
    BOOL changed = ![_lineAttrs isEqualToDictionary:lineAttrs];
    _lineAttrs = lineAttrs;
    _attrsChanged = changed;
    return changed;
}

- (BOOL) areAttributesChanged
{
    BOOL changed = _attrsChanged;
    _attrsChanged = NO;
    return changed;
}

#pragma mark - Layer

- (void) initDestinationLayer
{
    _destinationLineSublayer = [[CALayer alloc] init];
    _destinationLineSublayer.frame = self.bounds;
    _destinationLineSublayer.contentsCenter = self.layer.contentsCenter;
    _destinationLineSublayer.contentsScale = [[UIScreen mainScreen] scale];
    _destinationLineDelegate = [[OADestinationLineDelegate alloc] initWithDestinationLine:self];
    _destinationLineSublayer.delegate = _destinationLineDelegate;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    _destinationLineSublayer.frame = self.bounds;
}

- (void) drawRect:(CGRect)rect
{
    [super drawRect:rect];
}

- (BOOL) updateLayer
{
    return [self updateAttributes];
}

- (BOOL) drawLayer
{
    if (_destinationLineSublayer.superlayer != self.layer)
        [self.layer insertSublayer:_destinationLineSublayer above:self.layer];
    [_destinationLineSublayer setNeedsDisplay];
    return YES;
}

- (void) clearLayers
{
    for (CALayer *layer in self.layer.sublayers)
        [layer removeFromSuperlayer];
}

#pragma mark - Drawing

- (void) drawLineArrowWidget:(OADestination *)destination
{
    [self clearLayers];
    [_destinationsArray addObject:destination];
    [self initDestinationLayer];
    if (_destinationLineSublayer.superlayer != self.layer)
        [self.layer insertSublayer:_destinationLineSublayer above:self.layer];
    [_destinationLineSublayer setNeedsDisplay];
}

- (void) drawDestinationLineLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if ([OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        UIGraphicsPushContext(ctx);
        NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
        OADestination *firstMarkerDestination = (destinations.count >= 1 ? destinations[0] : nil);
        OADestination *secondMarkerDestination = (destinations.count >= 2 ? destinations[1] : nil);
        if (layer == _destinationLineSublayer)
        {            
            if ([_settings.arrowsOnMap get])
            {
                if (firstMarkerDestination)
                    [self drawArrow:firstMarkerDestination inContext:ctx];
                if (secondMarkerDestination && [_settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
                    [self drawArrow:secondMarkerDestination inContext:ctx];
            }
        }
        UIGraphicsPopContext();
    }
}

#pragma mark - Arrows

- (void) drawArrow:(OADestination *)marker inContext:(CGContextRef)ctx
{
    const OsmAnd::LatLon markerLatLon(marker.latitude, marker.longitude);
    const auto markerPoint = OsmAnd::Utilities::convertLatLonTo31(markerLatLon);
    if(![_mapViewController.mapView isPositionVisible:markerPoint])
    {
        CGPoint screenCenter = [self changeCenter];
        CLLocationCoordinate2D screenCenterCoord = [self getPointCoord:[self changeCenter]];
        NSArray<NSValue *> *linePoints = [_mapViewController.mapView getVisibleLineFromLat:screenCenterCoord.latitude fromLon:screenCenterCoord.longitude toLat:marker.latitude toLon:marker.longitude];
        if (linePoints.count == 2)
        {
            CGPoint a = linePoints[0].CGPointValue;
            CGPoint b = linePoints[1].CGPointValue;
            double angle = [OAMapUtils getAngleBetween:a end:b] - (a.x > b.x ? M_PI : 0);

            NSString *colorName = _markerColors[marker.color];
            if (!colorName)
                colorName = _markerColors.allValues[0];
            
            CGContextSaveGState(ctx);
            {
                UIImage *fgImage = [UIImage imageNamed:kArrowFrame];
                UIImage *bgImage = [UIImage imageNamed:colorName];
                UIImage *shadow = [UIImage imageNamed:kArrowShadow];
                if (fgImage && bgImage && shadow)
                {
                    UIImage *arrowIcon = [self getArrowImage:fgImage
                                                     inImage:bgImage
                                                  withShadow:shadow];
                    if (arrowIcon)
                    {
                        CGRect imageRect = CGRectMake(0, 0, arrowIcon.size.width, arrowIcon.size.height);
                        CGContextTranslateCTM(ctx, screenCenter.x, screenCenter.y);
                        CGContextRotateCTM(ctx, angle);
                        CGContextTranslateCTM(ctx, (imageRect.size.width * -0.5) + kArrowOffset, imageRect.size.height * -0.5);
                        CGContextDrawImage(ctx, imageRect, arrowIcon.CGImage);
                    }
                }
                else
                {
                    NSLog(@"Faliled to create OADestinationsLineWidget image for colorName: %@", colorName);
                }
            }
            CGContextRestoreGState(ctx);
        }
    }
}

- (double) getStrokeWidth
{
    float strokeWidth = _lineAttrs[@"strokeWidth"] != nil ? _lineAttrs[@"strokeWidth"].floatValue : 6;
    return strokeWidth * kWidthCorrectionValue / [[UIScreen mainScreen] scale];
}

- (UIImage *)getArrowImage:(UIImage *)fgImage inImage:(UIImage *)bgImage withShadow:(UIImage *)shadow
{
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:bgImage.size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [shadow drawInRect:CGRectMake(0.0, 0.0, shadow.size.width, shadow.size.height)];
        [bgImage drawInRect:CGRectMake(0.0, 0.0, bgImage.size.width, bgImage.size.height)];
        [fgImage drawInRect:CGRectMake(0.0, 0.0, fgImage.size.width, fgImage.size.height)];
    }];
}

#pragma mark - Supporting methods

- (CGPoint) changeCenter
{
    return CGPointMake(self.frame.size.width * 0.5,
                       self.frame.size.height * 0.5 * _mapViewController.mapView.viewportYScale);
}

- (void) removeLineToDestinationPin:(OADestination *)destinationToRemove
{
    for (int index = 0; index < [_destinationsArray count]; index++)
    {
        if (_destinationsArray[index].latitude == destinationToRemove.latitude &&
            _destinationsArray[index].longitude == destinationToRemove.longitude)
            [_destinationsArray removeObject:_destinationsArray[index]];
    }
    [_destinationLineSublayer setNeedsDisplay];
}

- (CLLocationCoordinate2D) getPointCoord:(CGPoint)point
{
    point.x *= _mapViewController.mapView.contentScaleFactor;
    point.y *= _mapViewController.mapView.contentScaleFactor;
    OsmAnd::PointI location;
    [_mapViewController.mapView convert:point toLocation:&location];
    
    double lon = OsmAnd::Utilities::get31LongitudeX(location.x);
    double lat = OsmAnd::Utilities::get31LatitudeY(location.y);
    return CLLocationCoordinate2DMake(lat, lon);
}

@end
