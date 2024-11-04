//
//  OAZoomLevelWidget.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAZoomLevelWidget.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OAZoom.h"
#import "OsmAnd_Maps-Swift.h"

static const int ZOOM_OFFSET_FROM_31 = 17;
static const int MAX_RATIO_DIGITS = 3;

static NSString *kZoomKey = @"ZOOM";
static NSString *kMapScaleKey = @"MAP_SCALE";


@implementation OAZoomLevelWidget
{
    OAMapRendererView *_rendererView;
    ZoomLevelWidgetState *_widgetState;
    BOOL _isForceUpdate;
    EOAWidgetZoomLevelType _cachedZoomLevelType;
    int _cachedBaseZoom;
    int _cachedZoom;
    float _cachedZoomFloatPart;
    float _cachedMapDensity;
    int _cachedCenterX;
    int _cachedCenterY;
}

- (instancetype)initWithСustomId:(NSString *)customId
                         appMode:(OAApplicationMode *)appMode
                     widgetState:(ZoomLevelWidgetState *)widgetState
                    widgetParams:(NSDictionary *)widgetParams
{
    self = [super initWithType:OAWidgetType.devZoomLevel];
    if (self)
    {
        _widgetState = widgetState;
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        _rendererView = [OARootViewController instance].mapPanel.mapViewController.mapView;
        [self setText:@"-" subtext:@""];
        [self setIcon:@"widget_developer_map_zoom"];
        
        __weak OAZoomLevelWidget *selfWeak = self;
        self.updateInfoFunction = ^BOOL{
            [selfWeak updateInfo];
            return NO;
        };
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
        _isForceUpdate = YES;
        _cachedCenterX = -1;
        _cachedCenterY = -1;
    }
    return self;
}

- (void)onWidgetClicked
{
    _isForceUpdate = YES;
    if ([_widgetState.typePreference get] == EOAWidgetZoom)
        [_widgetState.typePreference set:EOAWidgetMapScale];
    else
        [_widgetState.typePreference set:EOAWidgetZoom];
    [self updateInfo];
}

- (BOOL)isUpdateNeeded {
    return _isForceUpdate;
}

- (void)copySettings:(OAApplicationMode *)appMode customId:(NSString *)customId
{
    [super copySettings:appMode customId:customId];
    [_widgetState copyPrefs:appMode customId:customId];
}

- (OATableDataModel *)getSettingsData:(OAApplicationMode *)appMode
{
    OATableDataModel *data = [[OATableDataModel alloc] init];
    OATableSectionData *section = [data createNewSection];
    section.headerText = OALocalizedString(@"shared_string_settings");

    OATableRowData *row = section.createNewRow;
    row.cellType = OAValueTableViewCell.getCellIdentifier;
    row.key = @"value_pref";
    NSString *title = OALocalizedString(@"shared_string_show");
    row.title = title;
    row.descr = title;

    [row setObj:_widgetState.typePreference forKey:@"pref"];
    [row setObj:[self getTitle:(EOAWidgetZoomLevelType)[_widgetState.typePreference get:appMode]] forKey:@"value"];
    [row setObj:self.getPossibleValues forKey:@"possible_values"];
   
    return data;
}

- (NSString *)getTitle:(EOAWidgetZoomLevelType)type
{
    switch (type)
    {
        case EOAWidgetZoom:
            return OALocalizedString(@"map_widget_zoom_level");
        case EOAWidgetMapScale:
            return OALocalizedString(@"map_widget_map_scale");
        default:
            return @"";
    }
}

- (NSArray<OATableRowData *> *) getPossibleValues
{
    NSMutableArray<OATableRowData *> *res = [NSMutableArray array];

    OATableRowData *row = [[OATableRowData alloc] init];
    row.cellType = OASimpleTableViewCell.getCellIdentifier;
    [row setObj:kZoomKey forKey:@"value"];
    row.title = [self getTitle:EOAWidgetZoom];
    [res addObject:row];

    row = [[OATableRowData alloc] init];
    row.cellType = OASimpleTableViewCell.getCellIdentifier;
    [row setObj:kMapScaleKey forKey:@"value"];
    row.title = [self getTitle:EOAWidgetMapScale];
    [res addObject:row];

    return res;
}

- (int)calculateMapScale
{
       UIScreen *screen = [UIScreen mainScreen];
       CGFloat ppi = screen.ppi;
       CGFloat pixWidth = screen.nativeBounds.size.width;

       CGFloat pixelsPerMeter = ppi * 100.0 / 2.54;

       double realScreenWidthInMeters = pixWidth / pixelsPerMeter;

       double mapScreenWidthInMeters = _rendererView.currentPixelsToMetersScaleFactor * pixWidth;

       return (int)(mapScreenWidthInMeters / realScreenWidthInMeters);
}


- (FormattedValue *)formatMapScale:(int)mapScale
{
    int digitsCount = (int)(log10(mapScale) + 1);
    
    if (digitsCount >= 7)
    {
        return [self formatBigMapScale:mapScale
                                digits:digitsCount
                   insignificantDigits:6
                                   unit:@"M"];
    }
    else if (digitsCount >= 4)
    {
        return [self formatBigMapScale:mapScale
                                digits:digitsCount
                   insignificantDigits:3
                                   unit:@"K"];
    }
    else
    {
        NSMutableArray *valueUnitArray = [NSMutableArray array];
        [OAOsmAndFormatter formatValue:mapScale unit:@"" forceTrailingZeroes:NO decimalPlacesNumber:0 valueUnitArray:valueUnitArray];
        NSDictionary<NSString *, NSString *> *result = [self getValueAndUnitWithArray:valueUnitArray];
        if (result)
        {
            return [[FormattedValue alloc] initWithValueSrc:0 value:result[@"value"] unit:result[@"unit"]];
        }
        return nil;
    }
}

- (FormattedValue *)formatBigMapScale:(int)mapScale
                               digits:(int)digits
                  insignificantDigits:(int)insignificantDigits
                                   unit:(NSString *)unit
{
    int intDigits = digits - insignificantDigits;
    int fractionalDigits = MAX(0, MAX_RATIO_DIGITS - intDigits);
    int removeExcessiveDigits = mapScale / (int)pow(10, insignificantDigits - fractionalDigits);
    float roundedMapScale = (float)(removeExcessiveDigits / pow(10, fractionalDigits));
    
    NSMutableArray *valueUnitArray = [NSMutableArray array];
    [OAOsmAndFormatter formatValue:roundedMapScale unit:unit forceTrailingZeroes:YES decimalPlacesNumber:fractionalDigits valueUnitArray:valueUnitArray];
    NSDictionary<NSString *, NSString *> *result = [self getValueAndUnitWithArray:valueUnitArray];
    if (result)
    {
        return [[FormattedValue alloc] initWithValueSrc:0 value:result[@"value"] unit:result[@"unit"]];
    }
    return nil;
}

- (void)setZoomLevelText:(int)zoomBaseWithOffset
               zoomBase:(int)zoomBase
             zoomFraction:(float)zoomFraction
             mapDensity:(float)mapDensity
{
    
    float visualZoom = [OAZoom floatPartToVisual:zoomFraction];
    float targetPixelScale = powf(2.0f, zoomBase - zoomBaseWithOffset);
    float offsetFromLogicalZoom = [self getZoomDeltaFromMapScale:targetPixelScale * visualZoom * mapDensity];
    float preFormattedOffset = roundf(fabs(offsetFromLogicalZoom) * 100) / 100.0f;
    
    NSString *formattedOffset = [OAOsmAndFormatter
                                 formatValue:preFormattedOffset
                                 unit:@""
                                 forceTrailingZeroes:YES
                                 decimalPlacesNumber:2
                                 valueUnitArray:nil];
        
    NSString *sign = offsetFromLogicalZoom < 0 ? @"-" : @"+";
    [self setText:[NSString stringWithFormat:@"%d", zoomBaseWithOffset] subtext:[NSString stringWithFormat:@"%@%@", sign, formattedOffset]];
}

- (float)getZoomDeltaFromMapScale:(float)mapScale
{
    double log2Value = log(mapScale) / log(2.0);
    BOOL powerOfTwo = fabs(log2Value - round(log2Value)) < 0.001;

    if (powerOfTwo)
    {
        return round(log2Value);
    }

    int prevIntZoom;
    int nextIntZoom;

    if (mapScale >= 1.0f)
    {
        prevIntZoom = (int)log2Value;
        nextIntZoom = prevIntZoom + 1;
    }
    else
    {
        nextIntZoom = (int)log2Value;
        prevIntZoom = nextIntZoom - 1;
    }

    float prevPowZoom = powf(2.0f, prevIntZoom);
    float nextPowZoom = powf(2.0f, nextIntZoom);
    double zoomFloatPart = fabs(mapScale - prevPowZoom) / (nextPowZoom - prevPowZoom);

    return prevIntZoom + zoomFloatPart;
}

- (nullable NSDictionary<NSString *, NSString *> *)getValueAndUnitWithArray:(NSMutableArray *)valueUnitArray
{
    if (valueUnitArray.count == 2)
    {
        NSString *value = [valueUnitArray objectAtIndex:0];
        NSString *unit = [valueUnitArray objectAtIndex:1];
        
        if ([value isKindOfClass:[NSString class]] && [unit isKindOfClass:[NSString class]])
        {
            return @{@"value": value, @"unit": unit};
        }
    }
    
    return nil;
}

- (BOOL)updateInfo
{
    OAMapRendererView *mapView = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.view;
    OsmAnd::LatLon centerLatLon = OsmAnd::Utilities::convert31ToLatLon(mapView.target31);
    
    int x31 = OsmAnd::Utilities::get31TileNumberX(centerLatLon.longitude);
    int y31 = OsmAnd::Utilities::get31TileNumberY(centerLatLon.latitude);
    
    auto newCenterX = x31 >> ZOOM_OFFSET_FROM_31;
    auto newCenterY = y31 >> ZOOM_OFFSET_FROM_31;
    
    EOAWidgetZoomLevelType newZoomLevelType = [_widgetState getZoomLevelType];
    OAZoom *zoomObject = [[OAZoom alloc] initWitZoom:mapView.zoom minZoom:mapView.minZoom maxZoom:mapView.maxZoom];
    int baseZoom = [zoomObject getBaseZoom];
    int newZoom = mapView.zoom;
    
    float newZoomFloatPart = [zoomObject getZoomFloatPart] + [zoomObject getZoomAnimation];
    float newMapDensity = [[OAAppSettings sharedManager].mapDensity get];
    
    BOOL update = [self isUpdateNeeded]
            || newZoomLevelType != _cachedZoomLevelType
            || baseZoom != _cachedBaseZoom
            || newZoom != _cachedZoom
            || newZoomFloatPart != _cachedZoomFloatPart
            || newMapDensity != _cachedMapDensity
            || (newZoomLevelType == EOAWidgetMapScale && (newCenterX != _cachedCenterX || newCenterY != _cachedCenterY));
    
    if (update)
    {
        [self setContentTitle:[self getTitle:[_widgetState getZoomLevelType]]];
        
        _cachedCenterX = newCenterX;
        _cachedCenterY = newCenterY;
        _cachedZoomLevelType = newZoomLevelType;
        _cachedBaseZoom = baseZoom;
        _cachedZoom = newZoom;
        _cachedZoomFloatPart = newZoomFloatPart;
        _cachedMapDensity = newMapDensity;
        _isForceUpdate = NO;

        switch (newZoomLevelType)
        {
            case EOAWidgetMapScale:
                [self setMapScaleText];
                break;
            case EOAWidgetZoom:
            default:
                [self setZoomLevelText:baseZoom zoomBase:newZoom zoomFraction:newZoomFloatPart mapDensity:newMapDensity];
                break;
        }
    }
    return YES;
}

- (void)setMapScaleText
{
    int mapScale = [self calculateMapScale];
    FormattedValue *formattedMapScale = [self formatMapScale:mapScale];
    NSString *mapScaleStr = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon_with_space"), @"1", formattedMapScale.value];
    [self setText:mapScaleStr subtext:formattedMapScale.unit];
}

- (void) setImage:(UIImage *)image
{
    [super setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
