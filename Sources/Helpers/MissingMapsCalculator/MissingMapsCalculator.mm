//
//  MissingMapsCalculator.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 27.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "MissingMapsCalculator.h"
#import "OAMapUtils.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"

#include <OsmAndCore/Utilities.h>
#include <binaryRead.h>

static const double kDISTANCE_SPLIT = 50000;

@interface MissingMapsCalculatorPoint : NSObject
@property (nonatomic, strong) NSMutableArray<NSString *> *regions;
// 0 means routing data present but no HH data, nil means no data at all
@property (nonatomic, strong) NSMutableArray<NSNumber *> *hhEditions;
@property (nonatomic, strong) NSMutableOrderedSet<NSNumber *> *editionsUnique;

@end

@implementation MissingMapsCalculatorPoint

@end

@interface RegisteredMap : NSObject

@property (nonatomic, assign) BinaryMapFile *reader;
@property (nonatomic, assign) BOOL standard;
@property (nonatomic, assign) long edition;
@property (nonatomic, copy) NSString *downloadName;

@end

@implementation RegisteredMap

@end

@implementation MissingMapsCalculator {
    OAWorldRegion *_or;
//    BinaryMapIndexReader *_reader;
    NSMutableArray<NSString *> *_lastKeyNames;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _or = OsmAndApp.instance.worldRegion;
       // self.reader = [self.or prepareFile];
    }
    return self;
}

/*
 public static String getRegionName(String filename) {
     String lc = filename.toLowerCase();
     int firstPoint = lc.indexOf(".");
     if (firstPoint != -1) {
         lc = lc.substring(0, firstPoint);
     }
     int ind = lc.length() - 1;
     for (; ind > 0; ind--) {
         if ((lc.charAt(ind) >= '0' && lc.charAt(ind) <= '9') || lc.charAt(ind) == '_') {
             // timestamp ending or version ending
         } else {
             break;
         }
     }
     return lc.substring(0, ind + 1);
 }
 */

- (BOOL)checkIfThereAreMissingMaps:(std::shared_ptr<RoutingContext>)ctx
                             start:(CLLocation *)start
                           targets:(NSArray<CLLocation *> *)targets
                   checkHHEditions:(BOOL)checkHHEditions {
    NSTimeInterval tm = [NSDate timeIntervalSinceReferenceDate];
    _lastKeyNames = [NSMutableArray new];
    NSMutableArray<MissingMapsCalculatorPoint *> *pointsToCheck = [NSMutableArray new];
    string profile = profileToString(ctx->config->router->getProfile()); // use base profile
    // mb ordered dict?
    NSMutableDictionary<NSString *, RegisteredMap *> *knownMaps = [NSMutableDictionary new];
    
    [OARoutingHelper.sharedInstance.getRouteProvider checkInitializedForZoomLevel14];
    
    for (auto* file : getOpenMapFiles())
    {
        RegisteredMap *rmap = [RegisteredMap new];
        NSString *regionName = [NSString stringWithCString:file->inputName.c_str()
                                           encoding:[NSString defaultCStringEncoding]];
        

        
        rmap.downloadName = regionName.lastPathComponent; // with .obf //[self getRegionName:regionName];
        rmap.reader = file;
        rmap.standard = [_or getRegionDataByDownloadName:[rmap downloadName]] != nil;
        [knownMaps setObject:rmap forKey:[rmap downloadName]];

        for (const auto& rt : file->hhIndexes) {
            if (rt->profile == profile) {
                rmap.edition = rt->edition;
            }
        }
    }
    
    CLLocation *end = nil;
    for (int i = 0; i < [targets count]; i++) {
        CLLocation *s = (i == 0) ? start : targets[i - 1];
        end = targets[i];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck start:s end:end];
    }
    
    if (end != nil) {
        [self addPoint:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck point:end];
    }
    
    NSMutableOrderedSet<NSString *> *mapsToDownload = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<NSString *> *mapsToUpdate = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<NSNumber *> *presentTimestamps = nil;
    
    for (MissingMapsCalculatorPoint *p in pointsToCheck) {
        if (p.hhEditions == NULL) {
            if ([p.regions count] > 0) {
                [mapsToDownload addObject:[p.regions objectAtIndex:0]];
            }
        } else if (checkHHEditions) {
            if (presentTimestamps == nil) {
                presentTimestamps = [p.editionsUnique mutableCopy];
            } else if ([presentTimestamps count] > 0) {
                [presentTimestamps addObjectsFromArray:p.editionsUnique.array];
               // presentTimestamps.retainAll(p.editionsUnique); ???
            }
        }
    }
    
    if (presentTimestamps != nil && [presentTimestamps count] == 0) {
        long max = 0;
        for (MissingMapsCalculatorPoint *p in pointsToCheck) {
            if (p.editionsUnique != nil) {
                max = MAX([[p editionsUnique] lastObject].longValue, max);
            }
        }
        
        for (MissingMapsCalculatorPoint *p in pointsToCheck) {
            NSString *region = nil;
            for (int i = 0; p.hhEditions != NULL && i < p.hhEditions.count; i++) {
                if (p.hhEditions[i].intValue > 0) {
                    if (p.hhEditions[i].intValue != max) {
                        region = [p.regions objectAtIndex:i];
                    } else {
                        region = nil;
                        break;
                    }
                }
            }
            
            if (region != nil) {
                [mapsToUpdate addObject:region];
            }
        }
    }
    
    if ([mapsToDownload count] == 0 && [mapsToUpdate count] == 0) {
        BOOL mapsToDownloadIsEmpty = [mapsToDownload count] == 0;
        BOOL mapsToUpdateIsEmpty = [mapsToUpdate count] == 0;
        return NO;
    }
   // ctx.calculationProgress.requestMapsToUpdate = YES;
   self.missingMaps = [self convert:mapsToDownload];
   self.mapsToUpdate = [self convert:mapsToUpdate];
   
    NSLog(@"Check missing maps %lu points %.2f sec", [pointsToCheck count], ([NSDate timeIntervalSinceReferenceDate] - tm));

    return YES;
}

- (NSString *)getRegionName:(NSString *)filename {
    NSString *lc = [filename lowercaseString];
    NSInteger firstPoint = [lc rangeOfString:@"."].location;
    
    if (firstPoint != NSNotFound) {
        lc = [lc substringToIndex:firstPoint];
    }
    
    NSInteger ind = lc.length - 1;
    for (; ind > 0; ind--) {
        unichar character = [lc characterAtIndex:ind];
        if ((character >= '0' && character <= '9') || character == '_') {
            // timestamp ending or version ending
        } else {
            break;
        }
    }
    
    return [lc substringToIndex:ind + 1];
}

- (void)split:(std::shared_ptr<RoutingContext>)ctx
    knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
        start:(CLLocation *)s
          end:(CLLocation *)e {
    double distance = [OAMapUtils getDistance:s.coordinate second:e.coordinate];
    
    if (distance < kDISTANCE_SPLIT) {
        [self addPoint:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck point:s];
    } else {
        CLLocation *mid = [OAMapUtils calculateMidPoint:s s2:e];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck start:s end:mid];
        [self split:ctx knownMaps:knownMaps pointsToCheck:pointsToCheck start:mid end:e];
    }
}

- (void)addPoint:(std::shared_ptr<RoutingContext>)ctx
       knownMaps:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
   pointsToCheck:(NSMutableArray<MissingMapsCalculatorPoint *> *)pointsToCheck
           point:(CLLocation *)s {
    NSMutableArray<NSString *> *regions = [NSMutableArray array];
   // [_or getRegionsToDownloadWithLat:s.coordinate.latitude lon:s.coordinate.longitude keyNames:regions];
    
    NSArray<OAWorldRegion *> *regionsArray = [_or getWorldRegionsAt:s.coordinate.latitude longitude:s.coordinate.longitude];
    
    for (OAWorldRegion *region in regionsArray)
    {
        NSString *regionDownloadId = region.downloadsIdPrefix;
        if ([regionDownloadId hasSuffix:@"."]) {
            regionDownloadId = [regionDownloadId substringToIndex:[regionDownloadId length] - 1];
        }
        [regions addObject:regionDownloadId];
    }
    
    NSArray *sortedRegionsNameArray = [regions sortedArrayUsingComparator:^NSComparisonResult(NSString *str1, NSString *str2) {
         if (str1.length < str2.length) {
             return NSOrderedAscending;
         } else if (str1.length > str2.length) {
             return NSOrderedDescending;
         } else {
             return NSOrderedSame;
         }
     }];
    
    regions = [sortedRegionsNameArray copy];
    
    if (pointsToCheck.count == 0 || ![regions isEqualToArray:_lastKeyNames]) {
        MissingMapsCalculatorPoint *pnt = [MissingMapsCalculatorPoint new];
        _lastKeyNames = regions;
        pnt.regions = [[NSMutableArray alloc] initWithArray:regions];
        
        BOOL hasHHEdition = [self addMapEditions:knownMaps point:pnt];
        if (!hasHHEdition) {
            pnt.hhEditions = nil; // recreate
            
            // check non-standard maps
            int x31 = OsmAnd::Utilities::get31TileNumberX(s.coordinate.longitude);
            int y31 = OsmAnd::Utilities::get31TileNumberY(s.coordinate.latitude);
            
            int zoomToLoad = 14;
            
            for (RegisteredMap *r in knownMaps.allValues) {
                if (!r.standard) {
                    SearchQuery q((uint32_t)(x31 << zoomToLoad), (uint32_t)((x31 + 1) << zoomToLoad), (uint32_t)(y31 << zoomToLoad),
                                  (uint32_t)((y31 + 1) << zoomToLoad));
                    std::vector<RouteSubregion> tempResult;
                    if (r.reader->routingIndexes.size() > 0 &&  searchRouteSubregionsForBinaryMapFile(r.reader, &q, tempResult, false, false, false)) {
                        [pnt.regions insertObject:r.downloadName atIndex:0];
                    }
                }
            }
            
            [self addMapEditions:knownMaps point:pnt];
        }
        
        [pointsToCheck addObject:pnt];
    }
}

- (NSArray<OAWorldRegion *> *)convert:(NSOrderedSet<NSString *> *)mapsToDownload {
    if (mapsToDownload.count == 0) {
        return nil;
    }
    
    NSMutableArray<OAWorldRegion *> *worldRegions = [NSMutableArray array];
    
    for (NSString *mapName in mapsToDownload) {
        OAWorldRegion *worldRegion = [_or getRegionDataByDownloadName:mapName];
        if (worldRegion != nil) {
            [worldRegions addObject:worldRegion];
        }
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    return [[worldRegions sortedArrayUsingDescriptors:@[sort]] copy];
}

- (BOOL)addMapEditions:(NSDictionary<NSString *, RegisteredMap *> *)knownMaps
                 point:(MissingMapsCalculatorPoint *)pnt {
   BOOL hhEditionPresent = NO;

   for (int i = 0; i < pnt.regions.count; i++) {
       NSString *regionName = pnt.regions[i];
       
       if (knownMaps[regionName] != nil) {
           if (pnt.hhEditions == nil) {
               pnt.hhEditions = [[NSMutableArray alloc] initWithCapacity:pnt.regions.count];
               pnt.editionsUnique = [NSMutableOrderedSet orderedSet];
           }
           
           pnt.hhEditions[i] = @([knownMaps[regionName] edition]);
           hhEditionPresent |= pnt.hhEditions[i].intValue > 0;
           [pnt.editionsUnique addObject:@(pnt.hhEditions[i].intValue)];
       }
   }

   return hhEditionPresent;
}

- (NSString *)getErrorMessage {
    NSString *msg = @"";
    
    if (self.mapsToUpdate != nil) {
        msg = [NSString stringWithFormat:@"%@ need to be updated", self.mapsToUpdate];
    }
    
    if (self.missingMaps != nil) {
        if ([msg length] > 0) {
            msg = [msg stringByAppendingString:@" and "];
        }
        msg = [NSString stringWithFormat:@"%@ need to be downloaded", self.missingMaps];
    }
    
    msg = [NSString stringWithFormat:@"To calculate the route maps %@", msg];
    
    return msg;
}

@end

/*
 public class MissingMapsCalculator {
     protected static final Log log = PlatformUtil.getLog(MissingMapsCalculator.class);

     public static final double DISTANCE_SPLIT = 50000;
     private OsmandRegions or;
     private BinaryMapIndexReader reader;
     private List<String> lastKeyNames ;

     private static class Point {
         List<String> regions;
         long[] hhEditions; // 0 means routing data present but no HH data, null means no data at all
         TreeSet<Long> editionsUnique;
     }
     
     private static class RegisteredMap {
         BinaryMapIndexReader reader;
         boolean standard;
         long edition;
         String downloadName;
     }

     public MissingMapsCalculator() throws IOException {
         // could be cached
         or = new OsmandRegions();
         reader = or.prepareFile();
     }

     public MissingMapsCalculator(OsmandRegions osmandRegions) {
         or = osmandRegions;
     }
     
     public boolean checkIfThereAreMissingMaps(RoutingContext ctx, LatLon start, List<LatLon> targets, boolean checkHHEditions)
             throws IOException {
         long tm = System.nanoTime();
         lastKeyNames = new ArrayList<String>();
         List<Point> pointsToCheck = new ArrayList<>();
         String profile = ctx.getRouter().getProfile().getBaseProfile(); // use base profile
         Map<String, RegisteredMap> knownMaps = new TreeMap<>();
         
         for (BinaryMapIndexReader r : ctx.map.keySet()) {
             RegisteredMap rmap = new RegisteredMap();
             rmap.downloadName = Algorithms.getRegionName(r.getFile().getName());
             rmap.reader = r;
             rmap.standard = or.getRegionDataByDownloadName(rmap.downloadName) != null;
             knownMaps.put(rmap.downloadName, rmap);
             for (HHRouteRegion rt : r.getHHRoutingIndexes()) {
                 if (rt.profile.equals(profile)) {
                     rmap.edition = rt.edition;
                 }
             }
         }
         LatLon end = null;
         for (int i = 0; i < targets.size(); i++) {
             LatLon s = i == 0 ? start : targets.get(i - 1);
             end = targets.get(i);
             split(ctx, knownMaps, pointsToCheck, s, end);
         }
         if (end != null) {
             addPoint(ctx, knownMaps, pointsToCheck, end);
         }
         Set<String> mapsToDownload = new TreeSet<String>();
         Set<String> mapsToUpdate = new TreeSet<String>();
         Set<Long> presentTimestamps = null;
         for (Point p : pointsToCheck) {
             if (p.hhEditions == null) {
                 if (p.regions.size() > 0) {
                     mapsToDownload.add(p.regions.get(0));
                 }
             } else if (checkHHEditions) {
                 if (presentTimestamps == null) {
                     presentTimestamps = new TreeSet<Long>(p.editionsUnique);
                 } else if (!presentTimestamps.isEmpty()) {
                     presentTimestamps.retainAll(p.editionsUnique);
                 }
             }
         }
         // maps to update
         if (presentTimestamps != null && presentTimestamps.isEmpty()) {
             long max = 0;
             for (Point p : pointsToCheck) {
                 if (p.editionsUnique != null) {
                     max = Math.max(p.editionsUnique.last(), max);
                 }
             }
             for (Point p : pointsToCheck) {
                 String region = null;
                 for (int i = 0; p.hhEditions != null && i < p.hhEditions.length; i++) {
                     if (p.hhEditions[i] > 0) {
                         if (p.hhEditions[i] != max) {
                             region = p.regions.get(i);
                         } else {
                             region = null;
                             break;
                         }
                     }
                 }
                 if (region != null) {
                     mapsToUpdate.add(region);
                 }
             }
         }
         if (mapsToDownload.isEmpty() && mapsToUpdate.isEmpty()) {
             return false;
         }
         ctx.calculationProgress.requestMapsToUpdate = true;
         ctx.calculationProgress.missingMaps = convert(mapsToDownload);
         ctx.calculationProgress.mapsToUpdate = convert(mapsToUpdate);

         log.info(String.format("Check missing maps %d points %.2f sec", pointsToCheck.size(),
                 (System.nanoTime() - tm) / 1e9));
         return true;
     }

     private List<WorldRegion> convert(Set<String> mapsToDownload) {
         if (mapsToDownload.isEmpty()) {
             return null;
         }
         List<WorldRegion> l = new ArrayList<WorldRegion>();
         for (String m : mapsToDownload) {
             WorldRegion wr = or.getRegionDataByDownloadName(m);
             if (wr != null) {
                 l.add(wr);
             }
         }
         return l;
     }

     private void addPoint(RoutingContext ctx, Map<String, RegisteredMap> knownMaps, List<Point> pointsToCheck, LatLon s) throws IOException {
         List<String> regions = new ArrayList<String>();
         or.getRegionsToDownload(s.getLatitude(), s.getLongitude(), regions);
         Collections.sort(regions, new Comparator<String>() {

             @Override
             public int compare(String o1, String o2) {
                 return -Integer.compare(o1.length(), o2.length());
             }
         });
         if (pointsToCheck.size() == 0 || !regions.equals(lastKeyNames)) {
             Point pnt = new Point();
             lastKeyNames = regions;
             pnt.regions = new ArrayList<String>(regions);
             boolean hasHHEdition = addMapEditions(knownMaps, pnt);
             if (!hasHHEdition) {
                 pnt.hhEditions = null; // recreate
                 // check non-standard maps
                 int x31 = MapUtils.get31TileNumberX(s.getLongitude());
                 int y31 = MapUtils.get31TileNumberY(s.getLatitude());
                 for (RegisteredMap r : knownMaps.values()) {
                     if (!r.standard) {
                         if (r.reader.containsRouteData() && r.reader.containsActualRouteData(x31, y31, null)) {
                             pnt.regions.add(0, r.downloadName);
                         }
                     }
                 }
                 addMapEditions(knownMaps, pnt);
             }
             pointsToCheck.add(pnt);
         }
     }
     
     private boolean addMapEditions(Map<String, RegisteredMap> knownMaps, Point pnt) {
         boolean hhEditionPresent = false;
         for (int i = 0; i < pnt.regions.size(); i++) {
             String regionName = pnt.regions.get(i);
             if (knownMaps.containsKey(regionName)) {
                 if (pnt.hhEditions == null) {
                     pnt.hhEditions = new long[pnt.regions.size()];
                     pnt.editionsUnique = new TreeSet<Long>();
                 }
                 pnt.hhEditions[i] = knownMaps.get(regionName).edition;
                 hhEditionPresent |= pnt.hhEditions[i] > 0;
                 pnt.editionsUnique.add(pnt.hhEditions[i]);
             }
         }
         return hhEditionPresent;
     }

     private void split(RoutingContext ctx, Map<String, RegisteredMap> knownMaps, List<Point> pointsToCheck, LatLon s, LatLon e) throws IOException {
         if (MapUtils.getDistance(s, e) < DISTANCE_SPLIT) {
             addPoint(ctx, knownMaps, pointsToCheck, s);
             // pointsToCheck.add(e); // add only start end is separate
         } else {
             LatLon mid = MapUtils.calculateMidPoint(s, e);
             split(ctx, knownMaps, pointsToCheck, s, mid);
             split(ctx, knownMaps, pointsToCheck, mid, e);
         }
     }

     public void close() throws IOException {
         if (reader != null) {
             reader.close();
         }
     }

     public String getErrorMessage(RoutingContext ctx) {
         String msg = "";
         if (ctx.calculationProgress.mapsToUpdate != null) {
             msg = ctx.calculationProgress.mapsToUpdate + " need to be updated";
         }
         if (ctx.calculationProgress.missingMaps != null) {
             if (msg.length() > 0) {
                 msg += " and ";
             }
             msg = ctx.calculationProgress.missingMaps + " need to be downloaded";
         }
         msg = "To calculate the route maps " + msg;
         return msg;
     }

 }
 
 
 */
