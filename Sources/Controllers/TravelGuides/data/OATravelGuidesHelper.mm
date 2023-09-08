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

#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Utilities.h>

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


+ (NSArray<OAFoundAmenity *> *) searchAmenity:(double)lat lon:(double)lon reader:(NSString *)reader radius:(int)radius searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish
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
    NSArray<OAPOI *> *foundPoints = [OAPOIHelper findTravelGuides:searchFilter location:locI bbox31:bbox31 reader:reader publish:publish];
    
    NSMutableArray<OAFoundAmenity *> *result = [NSMutableArray array];
    for (OAPOI *point in foundPoints)
    {
        OAPOIAdapter *amenity = [[OAPOIAdapter alloc] initWithPOI:point];
        OAFoundAmenity *found = [[OAFoundAmenity alloc] initWithFile:reader amenity: amenity];
        [result addObject:found];
    }
    return result;
}

+ (void) searchAmenity:(NSString *)searchQuerry categoryName:(NSString *)categoryName radius:(int)radius lat:(double)lat lon:(double)lon reader:(NSString *)reader publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    [OAPOIHelper.sharedInstance findTravelGuidesByKeyword:searchQuerry categoryName:nil poiTypeName:nil location:locI radius:radius reader:reader publish:publish];
}

+ (void) searchAmenity:(int)x y:(int)y left:(int)left right:(int)right top:(int)top bottom:(int)bottom  reader:(NSString *)reader searchFilter:(NSString *)searchFilter publish:(BOOL(^)(OAPOIAdapter *poi))publish
{
    OsmAnd::PointI location = OsmAnd::PointI(x, y);
    OsmAnd::PointI topLeft = OsmAnd::PointI(left, top);
    OsmAnd::PointI bottomRight = OsmAnd::PointI(right, bottom);
    OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
    [OAPOIHelper findTravelGuides:searchFilter location:location bbox31:bbox31 reader:reader publish:publish];
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
    //TODO: add correct type
    NSMutableArray<id> *segmentList = [NSMutableArray array];
    
    NSMutableArray<OAPOIAdapter *> *pointList = [NSMutableArray array];
    for (NSString *reader in readers)
    {
        if (article.file != nil && ![article.file isEqualToString: reader])
        {
            continue;
        }

        if ([article isKindOfClass:OATravelGpx.class])
        {
            OsmAnd::PointI location = OsmAnd::PointI(article.lat, article.lon);
            OsmAnd::PointI topLeft = OsmAnd::PointI(0, 0);
            OsmAnd::PointI bottomRight = OsmAnd::PointI(INT_MAX, INT_MAX);
            OsmAnd::AreaI bbox31 =  OsmAnd::AreaI(topLeft, bottomRight);
            
            //TODO: implement or find gpx search in obf
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
            [OAPOIHelper.sharedInstance findTravelGuidesByKeyword:article.title categoryName:[article getPointFilterString] poiTypeName:nil location:location radius:article.routeRadius reader:reader publish:publish];
        }
        else
        {
            [OAPOIHelper findTravelGuides:[article getPointFilterString] location:location bbox31:bbox31 reader:reader publish:publish];
        }
        
        if (segmentList.count > 0)
        {
            break;
        }
    }
    
    OAGPXMutableDocument *gpxFile = nil;
    NSString *description = article.descr;
    NSString *title = [OAUtilities isValidFileName:description] ? description : article.title;
    if (segmentList.count > 0)
    {
        BOOL hasAltitude = NO;
        OATrack *track = [[OATrack alloc] init];
        
        //TODO: implement
        //for (BinaryMapDataObject segment : segmentList) {
        //}
        
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
//    OAGPXDocument *gpx = document.object;
//    return [OAGPXDatabase.sharedDb buildGpxItem:path.lastPathComponent path:path title:title desc:gpx.metadata.desc bounds:gpx.bounds document:document.object];
    
    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
    OAGPXDocument *gpxDoc = document.object;
    OAGPX *gpx = [OAGPXDatabase.sharedDb buildGpxItem:path.lastPathComponent path:path title:title desc:gpxDoc.metadata.desc bounds:gpxDoc.bounds document:gpxDoc];
    [gpxDb replaceGpxItem:gpx];
    [gpxDb save];
    return gpx;
}

//+ (void) addGpxToDb:(OAGPX *)gpx path:(NSString *)path
//{
//    OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
//    NSString *gpxFilePath = [OAUtilities getGpxShortPath:path];
////    OAGPX *oldGpx = [gpxDb getGPXItem:gpxFilePath];
////    OAGPX *gpx = [gpxDb buildGpxItem:gpxFilePath title:_savedGpxFile.metadata.name desc:_savedGpxFile.metadata.desc bounds:_savedGpxFile.bounds document:_savedGpxFile];
//    OAGPX *gpx = [gpxDb buildGpxItem:gpxFilePath title:_savedGpxFile.metadata.name desc:_savedGpxFile.metadata.desc bounds:_savedGpxFile.bounds document:_savedGpxFile];
////    if (oldGpx)
////    {
////        gpx.showArrows = oldGpx.showArrows;
////        gpx.showStartFinish = oldGpx.showStartFinish;
////        gpx.color = oldGpx.color;
////        gpx.coloringType = oldGpx.coloringType;
////        gpx.width = oldGpx.width;
////        gpx.splitType = oldGpx.splitType;
////        gpx.splitInterval = oldGpx.splitInterval;
////    }
//    [gpxDb replaceGpxItem:gpx];
//    [gpxDb save];
//}

+ (NSString *) selectedGPXFiles:(NSString *)fileName
{
    return [OASelectedGPXHelper.instance selectedGPXFiles:fileName];
}


@end
