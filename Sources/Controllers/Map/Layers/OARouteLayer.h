//
//  OARouteLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseVectorLinesLayer.h"

#define kCustomRouteWidthMin 1
#define kCustomRouteWidthMax 36

@class OATrackChartPoints, OAPreviewRouteLineInfo;

@interface OARouteLayer : OABaseVectorLinesLayer

- (void) refreshRoute;

- (void) showCurrentStatisticsLocation:(OATrackChartPoints *) trackPoints;
- (void) hideCurrentStatisticsLocation;

- (OAPreviewRouteLineInfo *) getPreviewRouteLineInfo;
- (void) setPreviewRouteLineInfo:(OAPreviewRouteLineInfo *)previewInfo;

@end
