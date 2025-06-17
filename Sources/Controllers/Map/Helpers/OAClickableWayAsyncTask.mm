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
    //TODO: implement
//    BOOL result = [self readHeightData:_clickableWay];
//    return result ? _clickableWay : nil;
    
    //TODO: delete after readHeightData implementation
    return _clickableWay;
}

- (void)onPostExecute:(id)result
{
    [self openAsGpxFile:result];
    [super onPostExecute:result];
}

- (BOOL) readHeightData:(OAClickableWay *)clickableWay
{
    return NO;
}

//TODO: delete

//private boolean readHeightData(@Nullable ClickableWay clickableWay, @Nullable Cancellable canceller) {
//    if (clickableWay != null) {
//        HeightDataLoader loader = new HeightDataLoader(app.getResourceManager().getReverseGeocodingMapFiles());
//        List<WptPt> waypoints =
//                loader.loadHeightDataAsWaypoints(clickableWay.getOsmId(), clickableWay.getBbox(), canceller);
//        if ((canceller == null || !canceller.isCancelled())
//                && !Algorithms.isEmpty(waypoints)
//                && !Algorithms.isEmpty(clickableWay.getGpxFile().getTracks())
//                && !Algorithms.isEmpty(clickableWay.getGpxFile().getTracks().get(0).getSegments())) {
//            clickableWay.getGpxFile().getTracks().get(0).getSegments().get(0).setPoints(waypoints);
//            return true;
//        }
//    }
//    return false;
//}

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

//TODO: delete

//private boolean openAsGpxFile(@Nullable ClickableWay clickableWay) {
//    MapActivity mapActivity = view.getMapActivity();
//    if (clickableWay != null && mapActivity != null) {
//        GpxFile gpxFile = clickableWay.getGpxFile();
//        GpxTrackAnalysis analysis = gpxFile.getAnalysis(0);
//        String safeFileName = clickableWay.getGpxFileName() + GPX_FILE_EXT;
//        File file = new File(FileUtils.getTempDir(app), safeFileName);
//        WptPt selectedPoint = clickableWay.getSelectedGpxPoint().getSelectedPoint();
//        GpxUiHelper.saveAndOpenGpx(mapActivity, file, gpxFile, selectedPoint, analysis, null, true);
//        return true;
//    }
//    return false;
//}

@end
