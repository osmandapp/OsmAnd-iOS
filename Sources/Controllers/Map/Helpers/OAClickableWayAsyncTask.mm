//
//  OAClickableWayAsyncTask.mm
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAClickableWayAsyncTask.h"
#import "OAClickableWay.h"
#import "OASelectedGpxPoint.h"
#import "OAGPXUIHelper.h"
#import "OAHeightDataLoader.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAClickableWayAsyncTask
{
    OAClickableWay *_clickableWay;
}

- (instancetype)initWithClickableWay:(OAClickableWay *)clickableWay
{
    self = [super init];
    if (self) {
        _clickableWay = clickableWay;
    }
    return self;
}

- (id)doInBackground
{
    BOOL result = [self readHeightData:_clickableWay];
    return result ? _clickableWay : nil;
}

- (void)onPostExecute:(id)result
{
    [self openAsGpxFile:result];
    [super onPostExecute:result];
}

- (BOOL) readHeightData:(OAClickableWay *)clickableWay
{
    OAHeightDataLoader *loader = [[OAHeightDataLoader alloc] init];
    NSMutableArray<OASWptPt *> *waypoints = [loader loadHeightDataAsWaypoints:[clickableWay getOsmId] bbox31:[clickableWay getBbox]];
    
    if (!NSArrayIsEmpty(waypoints) &&
        clickableWay.getGpxFile.tracks &&
        clickableWay.getGpxFile.tracks[0].segments)
    {
        [clickableWay.getGpxFile.tracks[0].segments[0] setPoints:waypoints];
        return YES;
    }
    return NO;
}

- (BOOL) openAsGpxFile:(OAClickableWay *)clickableWay
{
    if (clickableWay)
    {
        OASGpxFile *gpxFile = [clickableWay getGpxFile];
        OASGpxTrackAnalysis *analysis = [gpxFile getAnalysisFileTimestamp:0];
        NSString *name = [clickableWay getGpxFileName];
        NSString *safeFileName = [[clickableWay getGpxFileName] stringByAppendingString:GPX_FILE_EXT];
        OASWptPt *selectedPoint = [[clickableWay getSelectedGpxPoint] getSelectedPoint];
        [OAGPXUIHelper saveAndOpenGpx:name filepath:safeFileName gpxFile:gpxFile selectedPoint:selectedPoint analysis:analysis routeKey:nil];
        return YES;
    }
    return NO;
}

@end
