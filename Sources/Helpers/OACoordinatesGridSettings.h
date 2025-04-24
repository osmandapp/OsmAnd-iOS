//
//  OACoordinatesGridSettings.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 23.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct ZoomRange {
    NSInteger min;
    NSInteger max;
} ZoomRange;

@class OAApplicationMode;

@interface OACoordinatesGridSettings : NSObject

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (int32_t)getGridFormatForAppMode:(OAApplicationMode *)appMode;
- (void)setGridFormat:(int32_t)format forAppMode:(OAApplicationMode *)appMode;
- (int)getDayGridColor;
- (int)getNightGridColor;
- (void)setGridColor:(NSInteger)color forAppMode:(OAApplicationMode *)appMode nightMode:(BOOL)nightMode;
- (int32_t)getGridLabelsPositionForAppMode:(OAApplicationMode *)appMode;
- (void)setGridLabelsPosition:(int32_t)position forAppMode:(OAApplicationMode *)appMode;
- (ZoomRange)getSupportedZoomLevels;
- (ZoomRange)getZoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode;
- (ZoomRange)getZoomLevels;
- (void)setZoomLevels:(ZoomRange)levels forAppMode:(OAApplicationMode *)appMode;

@end
