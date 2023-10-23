//
//  OATravelGuidesHelper.m
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATravelGuidesHelper.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocumentPrimitivesAdapter.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDocument.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAUtilities.h"
#import "OAQuickSearchHelper.h"
#import "OASearchUICore.h"
#import "OASearchSettings.h"
#import "OASearchPhrase.h"
#import "OANameStringMatcher.h"
#import "OAResourcesUIHelper.h"
#import "OAWikiArticleHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"
#import "OAMapAlgorithms.h"

#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/BinaryMapObject.h>

@implementation OAFoundAmenity

- (instancetype) initWithFile:(NSString *)file amenity:(OAPOIAdapter *)amenity
{
    self = [super init];
    if (self)
    {
        self.file = file;
        self.amenity = amenity;
    }
    return self;
}

@end


@implementation OATravelGuidesHelper


+ (void) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::AreaI bbox31;
    OsmAnd::PointI locI;
    if (radius != -1)
    {
        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
        bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, locI);
    }
    else
    {
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    }
    [OAPOIHelper findTravelGuides:searchFilter location:locI bbox31:bbox31 reader:reader publish:publish];
}

+ (void) searchAmenity:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom  reader:(NSString *)reader searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::PointI location = OsmAnd::PointI(x, y);
    OsmAnd::PointI topLeft = OsmAnd::PointI(left, top);
    OsmAnd::PointI bottomRight = OsmAnd::PointI(right, bottom);
    OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    [OAPOIHelper findTravelGuides:searchFilter location:location bbox31:bbox31 reader:reader publish:publish];
}

+ (void) searchAmenity:(NSString *)searchQuerry categoryName:(NSString *)categoryName radius:(int)radius lat:(double)lat lon:(double)lon reader:(NSString *)reader publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::AreaI bbox31;
    OsmAnd::PointI locI;
    if (radius != -1)
    {
        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
        bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, locI);
    }
    else
    {
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    }
    [OAPOIHelper.sharedInstance findTravelGuidesByKeyword:searchQuerry categoryName:categoryName poiTypeName:nil location:locI bbox31:bbox31 reader:reader publish:publish];
}


+ (OAWptPt *) createWptPt:(OAPOIAdapter *)amenity lang:(NSString *)lang
{
    OAPOI *poi;
    if (amenity && [amenity.object isKindOfClass:OAPOI.class])
        poi = (OAPOI *) amenity.object;
        
    OAWptPt *wptPt = [[OAWptPt alloc] init];
    wptPt.name = poi.name;
    wptPt.position = CLLocationCoordinate2DMake(poi.latitude, poi.longitude);
    wptPt.desc = poi.desc;
    
    if ([poi getSite])
    {
        OALink *gpxLink = [[OALink alloc] init];
        gpxLink.url = [[NSURL alloc] initWithString:[poi getSite]];
        wptPt.links = @[ gpxLink ];
    }
    
    NSString *color = [poi getColor];
    OAGPXColor *gpxColor = [OAGPXColor getColorFromName:color];
    if (gpxColor)
        [wptPt setColor:gpxColor.color];
    
    if ([poi gpxIcon])
        [wptPt setIcon:[poi gpxIcon]];

    NSString *category = [poi getTagSuffix:@"category_"];
    if (category)
    {
        wptPt.category = [OAUtilities capitalizeFirstLetter:category];
        wptPt.type = [OAUtilities capitalizeFirstLetter:category];
    }
    
    return wptPt;
}

+ (NSArray<NSString *> *) getTravelGuidesObfList
{
    OsmAndAppInstance app = OsmAndApp.instance;
    NSMutableArray<NSString *> *obfFilenames = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
    {
        if (resource->type == OsmAnd::ResourcesManager::ResourceType::Travel)
        {
            [obfFilenames addObject:resource->id.toNSString()];
        }
    }
    return obfFilenames;
}

+ (CLLocation *) getMapCenter
{
    OsmAndAppInstance app = OsmAndApp.instance;
    Point31 mapCenter = app.data.mapLastViewedState.target31;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(OsmAnd::PointI(mapCenter.x, mapCenter.y));
    return [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
}

+ (NSString *) getPatrialContent:(NSString *)content
{
    return [OAWikiArticleHelper getPartialContent:content];
}

+ (NSString *) normalizeFileUrl:(NSString *)url
{
    return [OAWikiArticleHelper normalizeFileUrl:url];
}

+ (NSString *) createGpxFile:(OATravelArticle *)article fileName:(NSString *)fileName
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL exists = [fileManager fileExistsAtPath:OsmAndApp.instance.gpxTravelPath];
    if (!exists)
        [fileManager createDirectoryAtPath:OsmAndApp.instance.gpxTravelPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    OAGPXDocument *gpx = [article gpxFile].object;
    NSString *filePath = [OsmAndApp.instance.gpxTravelPath stringByAppendingPathComponent:fileName];
    BOOL succeed = [gpx saveTo:filePath];
    return filePath;
}

+ (OAGPXDocumentAdapter *) buildGpxFile:(NSArray<NSString *> *)readers article:(OATravelArticle *)article
{
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;
    NSMutableArray<OAPOIAdapter *> *pointList = [NSMutableArray array];
    for (NSString *reader in readers)
    {
        if (article.file != nil && ![article.file isEqualToString: reader])
        {
            continue;
        }

        if ([article isKindOfClass:OATravelGpx.class])
        {
            segmentList = [self.class searchGpxMapObject:article];
        }
        
        //publish function
        BOOL (^publish)(OAPOIAdapter *amenity) = ^BOOL(OAPOIAdapter *amenity) {
            if ([amenity.getRouteId isEqualToString:article.routeId])
            {
                if ([[article getPointFilterString] isEqualToString:@"route_track_point"])
                {
                    [pointList addObject:amenity];
                }
                else
                {
                    NSString *amenityLang = [amenity getTagSuffix:@"lang_yes:"];
                    if ([article.lang isEqualToString:amenityLang])
                    {
                        [pointList addObject:amenity];
                    }
                }
            }
            return NO;
        };
        
        
        OsmAnd::PointI location = OsmAnd::PointI(0, 0);
        OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
        OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
        OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
        
        if (article.routeRadius >= 0)
        {
            OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(article.lat, article.lon));
            bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(article.routeRadius, locI);
        }
        
        if (article.title && article.title.length > 0)
        {
            [OAPOIHelper.sharedInstance findTravelGuidesByKeyword:article.title categoryName:[article getPointFilterString] poiTypeName:nil location:location bbox31:bbox31 reader:reader publish:publish];
        }
        else
        {
            [OAPOIHelper findTravelGuides:[article getPointFilterString] location:location bbox31:bbox31 reader:reader publish:publish];
        }
        
        if (segmentList.size() > 0)
        {
            break;
        }
    }
    
    OAGPXMutableDocument *gpxFile = nil;
    NSString *description = article.descr;
    NSString *title = [OAUtilities isValidFileName:description] ? description : article.title;
    if (segmentList.size() > 0)
    {
        BOOL hasAltitude = NO;
        OATrack *track = [[OATrack alloc] init];
        NSMutableArray<OATrkSegment *> *segments = [NSMutableArray array];
        for (auto& binaryMapObject : segmentList)
        {
            OATrkSegment *trkSegment = [[OATrkSegment alloc] init];
            NSMutableArray<OAWptPt *> *points = [NSMutableArray array];
            for (auto& point : binaryMapObject->points31)
            {
                const auto latLon = OsmAnd::Utilities::convert31ToLatLon(point);
                OAWptPt *wptPt = [[OAWptPt alloc] init];
                wptPt.position = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
                [points addObject:wptPt];
            }
            trkSegment.points = points;
            
            QString eleGraphValue;
            QString startEleValue;
            for (const auto& captionAttributeId : OsmAnd::constOf(binaryMapObject->captionsOrder))
            {
                QString tag = binaryMapObject->attributeMapping->decodeMap[captionAttributeId].tag;
                const auto& value = OsmAnd::constOf(binaryMapObject->captions)[captionAttributeId];
                if (tag == QString("ele_graph"))
                    eleGraphValue = value;
                if (tag == QString("start_ele"))
                    startEleValue = value;
            }
            
            if (eleGraphValue.size() > 0)
            {
                hasAltitude = YES;
                auto heightRes = [OAMapAlgorithms decodeIntHeightArrayGraph:eleGraphValue repeatBits:3];
                double startEle = startEleValue.toDouble();
                trkSegment = [OAMapAlgorithms augmentTrkSegmentWithAltitudes:trkSegment decodedSteps:heightRes startEle:startEle];
            }
           
            [segments addObject:trkSegment];
        }
        track.segments = segments;

        gpxFile = [[OAGPXMutableDocument alloc] initWithTitle:title lang:article.lang descr:article.content];
        if (article.imageTitle && article.imageTitle.length > 0)
        {
            NSString *link = [OATravelArticle getImageUrlWithImageTitle:article.imageTitle thumbnail:false];
            OALink *gpxLink = [[OALink alloc] init];
            gpxLink.url = [[NSURL alloc] initWithString:link];
            gpxFile.metadata.links = @[ gpxLink ];
        }

        [gpxFile addTrack:track];
        [gpxFile.metadata setExtension:@"ref" value:article.ref];
        gpxFile.hasAltitude = hasAltitude;
    }
    
    if (pointList.count > 0)
    {
        if (!gpxFile)
        {
            gpxFile = [[OAGPXMutableDocument alloc] initWithTitle:title lang:article.lang descr:article.content];
            if (article.imageTitle && article.imageTitle.length > 0)
            {
                NSString *link = [OATravelArticle getImageUrlWithImageTitle:article.imageTitle thumbnail:false];
                OALink *gpxLink = [[OALink alloc] init];
                gpxLink.url = [[NSURL alloc] initWithString:link];
                gpxFile.metadata.links = @[ gpxLink ];
            }
        }
        for (OAPOIAdapter *wayPoint in pointList)
        {
            OAWptPt *wpt = [self.class createWptPt:wayPoint lang:article.lang];
            
            [gpxFile addWpt:wpt];
        }
    }
    OAGPXDocumentAdapter *gpxAdapter = [[OAGPXDocumentAdapter alloc] init];
    gpxAdapter.object = gpxFile;
    article.gpxFile = gpxAdapter;
    return gpxAdapter;
}

+ (OAGPX *) buildGpx:(NSString *)path title:(NSString *)title document:(OAGPXDocumentAdapter *)document
{
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    OAGPXDocument *gpxDoc = document.object;
    OAGPX *gpx = [OAGPXDatabase.sharedDb buildGpxItem:path.lastPathComponent path:path title:title desc:gpxDoc.metadata.desc bounds:gpxDoc.bounds document:gpxDoc];
    [gpxDb replaceGpxItem:gpx];
    [gpxDb save];
    return gpx;
}

+ (NSString *) selectedGPXFiles:(NSString *)fileName
{
    return [OASelectedGPXHelper.instance selectedGPXFiles:fileName];
}

+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >) searchGpxMapObject:(OATravelGpx *)travelGpx
{
    OsmAndAppInstance app = OsmAndApp.instance;
    QList< std::shared_ptr<const OsmAnd::ObfFile> > files = app.resourcesManager->obfsCollection->getObfFiles();
    std::shared_ptr<const OsmAnd::ObfFile> res;
    for (std::shared_ptr<const OsmAnd::ObfFile> file : files)
    {
        NSString *path = file->filePath.toNSString();
        if ([path hasSuffix:travelGpx.file])
        {
            res = file;
            break;
        }
    }
    std::shared_ptr<OsmAnd::ObfDataInterface> obfsDataInterface = app.resourcesManager->obfsCollection->obtainDataInterface(res);
    
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > loadedBinaryMapObjects;
    QList< std::shared_ptr<const OsmAnd::Road> > loadedRoads;
    auto tileSurfaceType = OsmAnd::MapSurfaceType::Undefined;
    
    OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
    OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
    OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    
    obfsDataInterface->loadMapObjects(&loadedBinaryMapObjects, &loadedRoads, &tileSurfaceType, OsmAnd::ZoomLevel15, &bbox31);
    
    QList< std::shared_ptr<const OsmAnd::BinaryMapObject> > segmentList;
    
    for (auto& binaryMapObject : loadedBinaryMapObjects)
    {
        NSString *ref = @"";
        NSString *routeId = @"";
        NSString *name = @"";
                
        for (const auto& captionAttributeId : OsmAnd::constOf(binaryMapObject->captionsOrder))
        {
            QString tag = binaryMapObject->attributeMapping->decodeMap[captionAttributeId].tag;
            const auto& value = OsmAnd::constOf(binaryMapObject->captions)[captionAttributeId];
            if (tag == QString("ref"))
                ref = value.toNSString();
            if (tag == QString("route_id"))
                routeId = value.toNSString();
            if (tag == QString("name"))
                name = value.toNSString();
        }
        
        if ((ref == travelGpx.ref && routeId == travelGpx.routeId) || name == travelGpx.title)
        {
            segmentList.append(binaryMapObject);
        }
    }
    return segmentList;
}

@end
