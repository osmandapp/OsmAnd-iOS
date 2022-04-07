//
//  OAPreviewRouteLineLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseVectorLinesLayer.h"

@class OAPreviewRouteLineInfo;

@interface OAPreviewRouteLineLayer : OABaseVectorLinesLayer

- (void) refreshRoute:(OsmAnd::AreaI)area;
- (OAPreviewRouteLineInfo *) getPreviewRouteLineInfo;
- (void) setPreviewRouteLineInfo:(OAPreviewRouteLineInfo *)previewInfo;

@end
