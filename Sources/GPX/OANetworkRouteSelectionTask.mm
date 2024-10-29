//
//  OANetworkRouteSelectionTask.m
//  OsmAnd Maps
//
//  Created by Paul on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OANetworkRouteSelectionTask.h"
#import "OARouteKey.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"

#include <QBuffer>

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/NetworkRouteSelector.h>
#include <OsmAndCore/FunctorQueryController.h>

@implementation OANetworkRouteSelectionTask
{
    OsmAnd::AreaI _area;
    OARouteKey *_routeKey;
}

- (instancetype) initWithRouteKey:(OARouteKey *)key area:(NSArray *)area
{
    self = [super init];
    if (self) {
        _routeKey = key;
        OsmAnd::PointI tl([area[0] intValue], [area[1] intValue]);
        OsmAnd::PointI br([area[2] intValue], [area[3] intValue]);
        _area = OsmAnd::AreaI(tl, br);
    }
    return self;
}

- (void) execute:(void(^)(OASGpxFile *gpxFile))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        std::shared_ptr<const OsmAnd::IQueryController> ctrl;
        ctrl.reset(new OsmAnd::FunctorQueryController([self]
                                                      (const OsmAnd::IQueryController* const controller)
                                                      {
                                                          return _cancelled;
                                                      }));
        OsmAnd::NetworkRouteSelector networkRouteSelector(OsmAndApp.instance.resourcesManager->obfsCollection, nullptr, ctrl);
        auto key = _routeKey.routeKey;
        networkRouteSelector.setNetworkRouteKeyFilter(key);
        auto combined = networkRouteSelector.getRoutes(_area, true, &key);
        if (_cancelled)
            combined.clear();
        auto it = combined.find(key);
        if (it != combined.end())
        {
            auto gpx = it.value();
            dispatch_async(dispatch_get_main_queue(), ^{

                QByteArray byteArray;
                QBuffer buffer(&byteArray);
                buffer.open(QIODevice::WriteOnly);
                QXmlStreamWriter xmlWriter(&buffer);
                auto name = gpx->metadata ? gpx->metadata->name : QString();
                gpx->saveTo(xmlWriter, name);
                buffer.close();
                auto xmlString = QString::fromUtf8(byteArray);

                OASOkioBuffer *buf = [[OASOkioBuffer alloc] init];
                [buf writeUtf8String:xmlString.toNSString()];
                OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileSource:buf];
                onComplete(gpxFile);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                onComplete(nil);
            });
        }
    });
}

@end
