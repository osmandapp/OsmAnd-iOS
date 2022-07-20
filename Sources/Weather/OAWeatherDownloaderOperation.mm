//
//  OAWeatherDownloaderOperation.mm
//  OsmAnd Maps
//
//  Created by Skalii on 18.07.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherDownloaderOperation.h"
#import "OsmAndApp.h"
#import "OANetworkUtilities.h"
#import "OALinks.h"

#include <OsmAndCore/QtExtensions.h>
#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

@implementation OAWeatherDownloaderOperation
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;

    OAWorldRegion *_region;
    OsmAnd::TileId _tileId;
    NSDate *_date;
    OsmAnd::ZoomLevel _zoom;
    BOOL _calculateSizeLocal;
    BOOL _calculateSizeUpdates;

    NSURLSessionDataTask *_task;
}

- (instancetype)initWithRegion:(OAWorldRegion *)region
                        tileId:(OsmAnd::TileId)tileId
                          date:(NSDate *)date
                          zoom:(OsmAnd::ZoomLevel)zoom
            calculateSizeLocal:(BOOL)calculateSizeLocal
          calculateSizeUpdates:(BOOL)calculateSizeUpdates
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _weatherResourcesManager = _app.resourcesManager->getWeatherResourcesManager();

        _region = region;
        _tileId = tileId;
        _date = date;
        _zoom = zoom;
        _calculateSizeLocal = calculateSizeLocal;
        _calculateSizeUpdates = calculateSizeUpdates;
    }
    return self;
}

- (void)main
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd_hh00"];

    NSString *dateTimeStr = [dateFormatter stringFromDate:_date];
    NSString *geoTileUrl = [NSString stringWithFormat:@"%@%@/%@_%@_%@.tiff.gz",
            kWeatherTilesUrlPrefix,
            dateTimeStr,
            QString::number(_zoom).toNSString(),
            QString::number(_tileId.x).toNSString(),
            QString::number(15 - _tileId.y).toNSString()
    ];
    QDateTime dateTime = QDateTime::fromNSDate(_date).toUTC();
    QByteArray outData;
    BOOL containsTileId = _weatherResourcesManager->containsLocalTileId(_tileId, dateTime, _zoom, outData);
    if (_calculateSizeLocal)
    {
        [self onProgressUpdate:0 sizeLocal:outData.size() success:containsTileId];
        return;
    }
    _task = [OANetworkUtilities createDownloadTask:geoTileUrl
                                            params:@{}
                                              post:NO
                                              size:_calculateSizeUpdates
                                        onComplete:^(NSData *_Nullable data, NSURLResponse *_Nullable response, NSError *_Nullable error)
                                        {
                                            NSInteger sizeUpdates = 0;
                                            NSInteger sizeLocal = 0;
                                            BOOL success = data && ((NSHTTPURLResponse *) response).statusCode == 200 && !error;
                                            if (success)
                                            {
                                                sizeUpdates = response.expectedContentLength;
                                                if (!_calculateSizeUpdates && !containsTileId)
                                                {
                                                    NSString *path = [_app.weatherForecastPath stringByAppendingPathComponent:@"offline"];
                                                    NSString *fileName = [[geoTileUrl stringByReplacingOccurrencesOfString:kWeatherTilesUrlPrefix withString:@""]
                                                            stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
                                                    NSFileManager *manager = [NSFileManager defaultManager];
                                                    if (![manager fileExistsAtPath:path])
                                                    {
                                                        success = [manager createDirectoryAtPath:path
                                                                     withIntermediateDirectories:YES
                                                                                      attributes:nil
                                                                                           error:nil];
                                                    }

                                                    NSString *filePathGz = [path stringByAppendingPathComponent:fileName];
                                                    QString filePath = QString::fromNSString([filePathGz stringByDeletingPathExtension]);
                                                    if (success)
                                                        success = [data writeToFile:filePathGz atomically:YES];
                                                    if (success)
                                                    {
                                                        OsmAnd::ArchiveReader archive(QString::fromNSString(filePathGz));
                                                        bool ok = false;
                                                        const auto archiveItems = archive.getItems(&ok, true);
                                                        if (ok)
                                                        {
                                                            OsmAnd::ArchiveReader::Item tiffArchiveItem;
                                                            for (const auto &archiveItem: constOf(archiveItems))
                                                            {
                                                                if (!archiveItem.isValid() || (!archiveItem.name.endsWith(QStringLiteral(".tiff"))))
                                                                    continue;

                                                                tiffArchiveItem = archiveItem;
                                                                break;
                                                            }
                                                            success = tiffArchiveItem.isValid() && archive.extractItemToFile(tiffArchiveItem.name, filePath, true);
                                                            if (success)
                                                            {
                                                                auto tileFile = QFile(filePath);
                                                                success = tileFile.open(QIODevice::ReadOnly);
                                                                if (success)
                                                                {
                                                                    QByteArray fileData = tileFile.readAll();
                                                                    tileFile.close();
                                                                    success = !fileData.isEmpty();
                                                                    if (success)
                                                                    {
                                                                        success = _weatherResourcesManager->storeLocalTileData(_tileId, dateTime, _zoom, fileData);
                                                                        sizeLocal = fileData.size();
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        QFile(QString::fromNSString(filePathGz)).remove();
                                                        QFile(filePath).remove();
                                                    }
                                                }
                                            }
                                            if (sizeLocal == 0 && containsTileId && !outData.isEmpty())
                                                sizeLocal = outData.size();
                                            [self onProgressUpdate:sizeUpdates sizeLocal:sizeLocal success:success];
                                        }
    ];
    [_task resume];
}

- (void)cancel
{
    [_task cancel];
}

- (void)onProgressUpdate:(NSInteger)sizeUpdates sizeLocal:(NSInteger)sizeLocal success:(BOOL)success
{
    if (self.delegate)
    {
        [self.delegate onProgressUpdate:_region
                            sizeUpdates:sizeUpdates
                              sizeLocal:sizeLocal
                     calculateSizeLocal:_calculateSizeLocal
                   calculateSizeUpdates:_calculateSizeUpdates
                                success:success];
    }
}

@end
