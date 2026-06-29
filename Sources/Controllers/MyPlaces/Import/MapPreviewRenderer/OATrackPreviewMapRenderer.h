//
//  OATrackPreviewMapRenderer.h
//  OsmAnd
//
//  Created by Vitaliy Sova on 10.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class OASGpxFile;

NS_ASSUME_NONNULL_BEGIN

@interface OATrackPreviewMapRenderer : NSObject

+ (instancetype)shared;

- (void)renderGpxFile:(OASGpxFile *)gpxFile
              widthPx:(NSInteger)widthPx
             heightPx:(NSInteger)heightPx
              density:(float)density
           trackColor:(int)trackColor
           completion:(void (^)(UIImage * _Nullable image))completion;

- (void)cancelAll;

@end

NS_ASSUME_NONNULL_END
