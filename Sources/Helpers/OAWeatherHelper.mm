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
    if (self)
    {
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

- (void) updateMapPresentationEnvironment:(OAMapPresentationEnvironment *)mapPresentationEnvironment
{
    _mapPresentationEnvironment = mapPresentationEnvironment;
}

- (QList<OsmAnd::BandIndex>) getVisibleBands
{
    QList<OsmAnd::BandIndex> res;
    for (OAWeatherBand *band in _bands)
        if ([band isBandVisible])
            res << band.bandIndex;
    
    return res;
}

- (QHash<OsmAnd::BandIndex, std::shared_ptr<const OsmAnd::GeoBandSettings>>) getBandSettings
{
    QHash<OsmAnd::BandIndex, std::shared_ptr<const OsmAnd::GeoBandSettings>> result;
    for (OAWeatherBand *band in _bands)
    {
        auto contourStyleName = QString::fromNSString([band getContourStyleName]);
        
        NSDictionary<NSNumber *, NSArray<NSNumber *> *> *contourLevels = [band getContourLevels:self.mapPresentationEnvironment];
        QHash<OsmAnd::ZoomLevel, QList<double>> contourLevelsMap;
        for (NSNumber * zoomNum in contourLevels.allKeys)
        {
            NSArray<NSNumber *> *levelsList = contourLevels[zoomNum];
            QList<double> levels;
            for (NSNumber *level in levelsList)
                levels << level.doubleValue;
            
            contourLevelsMap.insert((OsmAnd::ZoomLevel)zoomNum.intValue, levels);
        }
        NSDictionary<NSNumber *, NSArray<NSString *> *> *contourTypes = [band getContourTypes:self.mapPresentationEnvironment];
        QHash<OsmAnd::ZoomLevel, QStringList> contourTypesMap;
        for (NSNumber * zoomNum in contourTypes.allKeys)
        {
            NSArray<NSString *> *typesList = contourTypes[zoomNum];
            QStringList types;
            for (NSString *type in typesList)
                types << QString::fromNSString(type);
            
            contourTypesMap.insert((OsmAnd::ZoomLevel)zoomNum.intValue, types);
        }

        auto settings = std::make_shared<const OsmAnd::GeoBandSettings>(
            QString::fromNSString([band getBandUnit]),
            QString::fromNSString([band getBandGeneralUnitFormat]),
            QString::fromNSString([band getBandPreciseUnitFormat]),
            QString::fromNSString([band getInternalBandUnit]),
            [band getBandOpacity],
            QString::fromNSString([band getColorFilePath]),
            contourStyleName,
            contourLevelsMap,
            contourTypesMap
        );
        result.insert((OsmAnd::BandIndex)band.bandIndex, settings);
    }
    return result;
}

@end
