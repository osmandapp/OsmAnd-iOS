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
#import "OsmAnd_Maps-Swift.h"

@implementation OAZoomLevelWidget
{
    OAMapRendererView *_rendererView;
    float _cachedZoom;
    ZoomLevelWidgetState *_widgetState;
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
    }
    return self;
}

- (BOOL) updateInfo
{
    float newZoom = [_rendererView zoom];
    BOOL isZoomChangeBigEnough = ABS(int(_cachedZoom * 100) - int(newZoom * 100)) > 1; //update with 0.01 step
    if (self.isUpdateNeeded || isZoomChangeBigEnough)
    {
        _cachedZoom = newZoom;
        NSString *cachedZoomText = [NSString stringWithFormat:@"%.2f", _cachedZoom];
        [self setText:cachedZoomText subtext:@""];
        [self setIcon:@"widget_developer_map_zoom"];
    }
    return YES;
}

- (OATableDataModel *)getSettingsData:(OAApplicationMode *)appMode
{
    OAWidgetType *type = _widgetState.widgetType;
    
    OATableDataModel *data = [[OATableDataModel alloc] init];
    OATableSectionData *section = [data createNewSection];
    section.headerText = OALocalizedString(@"shared_string_settings");
    SunPositionMode sunPositionMode = (SunPositionMode)[[_state getSunPositionPreference] get:appMode];

    if (type == OAWidgetType.sunPosition)
    {
        OATableRowData *row = section.createNewRow;
        row.cellType = OAValueTableViewCell.getCellIdentifier;
        row.key = @"value_pref";
        row.title = OALocalizedString(@"shared_string_mode");
        row.descr = OALocalizedString(@"shared_string_mode");
        [row setObj:_state.getSunPositionPreference forKey:@"pref"];
        
        [row setObj:[self getTitleForSunPositionMode:sunPositionMode] forKey:@"value"];
        [row setObj:self.getPossibleFormatValues forKey:@"possible_values"];
    }
    
    OATableRowData *row = section.createNewRow;
    row.cellType = OAValueTableViewCell.getCellIdentifier;
    row.key = @"value_pref";
    NSString *title = OALocalizedString(type == OAWidgetType.sunPosition ? @"shared_string_format" : @"recording_context_menu_show");

    row.title = title;
    row.descr = title;

    [row setObj:_state.getPreference forKey:@"pref"];
    [row setObj:[self getTitle:(EOASunriseSunsetMode)[_state.getPreference get:appMode] sunPositionMode:sunPositionMode] forKey:@"value"];
    [row setObj:self.getPossibleValues forKey:@"possible_values"];
   
    return data;
}

- (void)updateSimpleWidgetInfo
{
    OAMapRendererView *mapView = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.view;
    EOAWidgetZoomLevelType newZoomLevelType = [_widgetState getZoomLevelType];
    
    switch (newZoomLevelType) {
        case EOAWidgetMapScale:
          //  [self setMapScaleText];
            break;
        case EOAWidgetZoom:
        default:
//            [self setZoomLevelTextWithBaseZoom:baseZoom zoom:newZoom zoomFraction:newZoomFloatPart mapDensity:newMapDensity];
            break;
    }

//    RotatedTileBox *tileBox = mapView.rotatedTileBox;
//    NSInteger newCenterX = tileBox.center31X >> ZOOM_OFFSET_FROM_31;
//    NSInteger newCenterY = tileBox.center31Y >> ZOOM_OFFSET_FROM_31;
//    EOAWidgetZoomLevelType newZoomLevelType = [self.widgetState getZoomLevelType];
//    NSInteger baseZoom = mapView.baseZoom;
//    NSInteger newZoom = mapView.zoom;
//    float newZoomFloatPart = mapView.zoomFloatPart + self.mapView.zoomAnimation;
//    float newMapDensity = self.osmandMap.mapDensity; // [[OAAppSettings sharedManager].mapDensity get]
//
//    BOOL updateNeeded = [self shouldUpdateWithNewCenterX:newCenterX
//                                             newCenterY:newCenterY
//                                        newZoomLevelType:newZoomLevelType
//                                                  baseZoom:baseZoom
//                                                  newZoom:newZoom
//                                        newZoomFloatPart:newZoomFloatPart
//                                            newMapDensity:newMapDensity];
//
//    if (updateNeeded) {
//        self.cachedCenterX = newCenterX;
//        self.cachedCenterY = newCenterY;
//        self.cachedZoomLevelType = newZoomLevelType;
//        self.cachedBaseZoom = baseZoom;
//        self.cachedZoom = newZoom;
//        self.cachedZoomFloatPart = newZoomFloatPart;
//        self.cachedMapDensity = newMapDensity;
//
//        switch (newZoomLevelType) {
//            case MAP_SCALE:
//                [self setMapScaleText];
//                break;
//            case ZOOM:
//            default:
//                [self setZoomLevelTextWithBaseZoom:baseZoom zoom:newZoom zoomFraction:newZoomFloatPart mapDensity:newMapDensity];
//                break;
//        }
//    }
}

//- (void)setMapScaleText {
//    NSInteger mapScale = [self calculateMapScale];
//    FormattedValue *formattedMapScale = [self formatMapScale:mapScale];
//    NSString *mapScaleStr = [NSString stringWithFormat:@"1 %@", formattedMapScale.value];
//    [self setText:mapScaleStr unit:formattedMapScale.unit];
//}
//
//- (NSInteger)calculateMapScale {
//    UIScreen *screen = [UIScreen mainScreen];
//    OAMapRendererView *mapView = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.view;
//    OsmAnd::PointI windowSize = mapView.renderer->getState().windowSize;
//    
//    NSInteger pixWidth = windowSize.x;
//    NSInteger pixHeight = windowSize.y;
//
//    CGFloat averageRealDpi = (screen.scale * 72.0); // Example for average DPI
//    CGFloat pixelsPerMeter = averageRealDpi * 100 / 2.54;
//    double realScreenWidthInMeters = (double)pixWidth / pixelsPerMeter;
//    double mapScreenWidthInMeters = [self.mapView.rotatedTileBox getDistanceFromX:0 fromY:pixHeight / 2 toX:pixWidth toY:pixHeight / 2];
//
//    return (NSInteger)(mapScreenWidthInMeters / realScreenWidthInMeters);
//}


- (void) setImage:(UIImage *)image
{
    [super setImage:image.imageFlippedForRightToLeftLayoutDirection];
}

@end
