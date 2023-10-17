//
//  OASRTMPlugin.h
//  OsmAnd
//
//  Created by nnngrach on 08.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

@class OACommonBoolean;

@interface OASRTMPlugin : OAPlugin

@property (nonatomic) OACommonBoolean *enable3DMaps;

- (BOOL) isHeightmapEnabled;
- (BOOL) isHeightmapAllowed;
- (BOOL) is3DMapsEnabled;

@end
