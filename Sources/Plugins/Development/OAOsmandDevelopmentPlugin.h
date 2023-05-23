//
//  OAOsmandDevelopmentPlugin.h
//  OsmAnd
//
//  Created by nnngrach on 31.05.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@class OACommonBoolean;

@interface OAOsmandDevelopmentPlugin : OAPlugin

@property (nonatomic) OACommonBoolean *enableHeightmap;
@property (nonatomic) OACommonBoolean *enable3DMaps;
@property (nonatomic) OACommonBoolean *disableVertexHillshade3D;
@property (nonatomic) OACommonBoolean *generateSlopeFrom3DMaps;
@property (nonatomic) OACommonBoolean *generateHillshadeFrom3DMaps;

- (BOOL) isHeightmapEnabled;
- (BOOL) isHeightmapAllowed;
- (BOOL) is3DMapsEnabled;
- (BOOL) isDisableVertexHillshade3D;
- (BOOL) isGenerateSlopeFrom3DMaps;
- (BOOL) isGenerateHillshadeFrom3DMaps;

@end

NS_ASSUME_NONNULL_END
