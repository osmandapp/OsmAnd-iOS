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

- (void)toggleEnable;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (NSString *)gridFormatIdForAppMode:(OAApplicationMode *)appMode;
- (void)setGridFormatId:(NSString *)formatId forAppMode:(OAApplicationMode *)appMode;
- (NSString *)resolvedGridFormatIdForAppMode:(OAApplicationMode *)appMode;
- (int)dayGridColor;
- (int)nightGridColor;
- (void)setGridColor:(NSInteger)color forAppMode:(OAApplicationMode *)appMode nightMode:(BOOL)nightMode;
- (int32_t)gridLabelsPositionForAppMode:(OAApplicationMode *)appMode;
- (void)setGridLabelsPosition:(int32_t)position forAppMode:(OAApplicationMode *)appMode;
- (ZoomRange)supportedZoomLevels;
- (ZoomRange)supportedZoomLevelsForFormatId:(NSString *)formatId;
- (ZoomRange)zoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode;
- (ZoomRange)zoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode formatId:(NSString *)formatId;
- (ZoomRange)zoomLevels;
- (void)setZoomLevels:(ZoomRange)levels forAppMode:(OAApplicationMode *)appMode;
- (float)textScaleForAppMode:(OAApplicationMode *)appMode;

@end
