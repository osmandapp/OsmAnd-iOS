//
//  OARouteLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseVectorLinesLayer.h"

@class OAPreviewRouteLineInfo;

@interface OARouteLayer : OABaseVectorLinesLayer

@property (nonatomic, readonly) CLLocation *lastProj;

- (void) refreshRoute;
- (void) refreshRoute:(BOOL)forceRedraw;

- (OAPreviewRouteLineInfo *) getPreviewRouteLineInfo;
- (void) setPreviewRouteLineInfo:(OAPreviewRouteLineInfo *)previewInfo;

- (NSInteger)getCustomRouteWidthMin;
- (NSInteger)getCustomRouteWidthMax;

@end
