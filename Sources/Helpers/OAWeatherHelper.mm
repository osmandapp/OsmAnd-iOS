//
//  OAWeatherHelper.mm
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherHelper.h"
#import "OsmAndApp.h"

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
}

+ (OAWeatherHelper *) sharedInstance
{
    static OAWeatherHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWeatherHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _bands = @[
            [OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION]
        ];
    }
    return self;
}

- (QList<OsmAnd::BandIndex>) getVisibleBands
{
    QList<OsmAnd::BandIndex> res;
    for (OAWeatherBand *band in _bands)
        if ([band isBandVisible])
            res << band.bandIndex;
    
    return res;
}

- (QHash<OsmAnd::BandIndex, float>) getBandOpacityMap
{
    QHash<OsmAnd::BandIndex, float> bandOpacityMap;
    for (OAWeatherBand *band in _bands)
        bandOpacityMap.insert(band.bandIndex, [band getBandOpacity]);

    return bandOpacityMap;
}

- (QHash<OsmAnd::BandIndex, QString>) getBandColorProfilePaths
{
    QHash<OsmAnd::BandIndex, QString> bandColorProfilePaths;
    for (OAWeatherBand *band in _bands)
        bandColorProfilePaths.insert(band.bandIndex, QString::fromNSString([band getColorFilePath]));

    return bandColorProfilePaths;
}

@end
