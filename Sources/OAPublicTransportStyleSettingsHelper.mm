//
//  OAPublicTransportStuleSettingsHelper.m
//  OsmAnd
//
//  Created by nnngrach on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAPublicTransportStyleSettingsHelper.h"
#import "OsmAndApp.h"
#import "OAMapStyleSettings.h"
#import "OAAppSettings.h"

@implementation OAPublicTransportStyleSettingsHelper
{
    OsmAndAppInstance _app;
    OAAppSettings* _settings;
    OAMapStyleSettings* _styleSettings;
}

+ (OAPublicTransportStyleSettingsHelper *)sharedInstance
{
    static OAPublicTransportStyleSettingsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAPublicTransportStyleSettingsHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _styleSettings = [OAMapStyleSettings sharedInstance];
    }
    return self;
}


- (BOOL) getVisibilityForTransportLayer
{
    return _settings.mapSettingShowPublicTransport;
}

- (void) setVisibilityForTransportLayer:(BOOL)isVisible
{
    if (_settings.mapSettingShowPublicTransport)
        [self hideAllTransportStyles];
    else
        [self showEnabledTransportStyles];
    
    [_settings setMapSettingShowPublicTransport:isVisible];
}

- (void) toggleVisibilityForTransportLayer
{
    [self setVisibilityForTransportLayer: ![self getVisibilityForTransportLayer]];
}


- (void)hideAllTransportStyles
{
    NSArray* allTransportStyleParams = [self getAllTransportStyleParameters];
    for (OAMapStyleParameter *styleParam in allTransportStyleParams)
    {
        styleParam.value = @"false";
    }
    
    [self saveAllStyleParameters];
}

- (void)showEnabledTransportStyles
{
    NSMutableArray* storedVisibleStyleNames = [_settings.transportLayersVisible get];
    for (NSString *visibleStyleName in storedVisibleStyleNames)
    {
        OAMapStyleParameter *styleParam = [_styleSettings getParameter:visibleStyleName];
        styleParam.value = @"true";
    }
    
    [self saveAllStyleParameters];

}


- (NSArray *) getAllTransportStyleParameters
{
    return [_styleSettings getParameters:@"transport"];
}

- (BOOL) getVisibilityForStyleParameter:(NSString*)parameterName
{
    return [_settings.transportLayersVisible contain:parameterName];
}

- (void) setVisibility:(BOOL)isVisible forStyleParameter:(NSString*)parameterName
{
    if (isVisible)
        [_settings.transportLayersVisible addUnic:parameterName];
    else
        [_settings.transportLayersVisible remove:parameterName];
    
    
    if (_settings.mapSettingShowPublicTransport)
    {
        OAMapStyleParameter *renderParam = [_styleSettings getParameter:parameterName];
        renderParam.value = isVisible ? @"true" : @"false";
        [self saveStyleParameter:renderParam];
    }
}

- (BOOL) isAllTransportStylesHidden
{
    return [_settings.transportLayersVisible get].count == 0;
}


- (void) saveAllStyleParameters
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_styleSettings saveParameters];
        [[_app mapSettingsChangeObservable] notifyEvent];
    });
}

- (void) saveStyleParameter:(OAMapStyleParameter *)parameter
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_styleSettings save:parameter];
    });
}


- (NSString *) getIconNameForStyle:(NSString *)styleName
{
    NSString* imageName = @"";
    if ([styleName isEqualToString:@"tramTrainRoutes"])
        imageName = @"ic_custom_transport_tram";
    else if ([styleName isEqualToString:@"subwayMode"])
        imageName = @"ic_custom_transport_subway";
    else if ([styleName isEqualToString:@"transportStops"])
        imageName = @"ic_custom_transport_stop";
    else if ([styleName isEqualToString:@"publicTransportMode"])
        imageName = @"ic_custom_transport_stop";
    
    return imageName;
}
 
@end
