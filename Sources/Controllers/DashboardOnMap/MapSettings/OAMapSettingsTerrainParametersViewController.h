//
//  OAMapSettingsTerrainParametersViewController.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 08.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseScrollableHudViewController.h"

typedef NS_ENUM(NSInteger, EOATerrainSettingsType)
{
    EOATerrainSettingsTypeVisibility,
    EOATerrainSettingsTypeZoomLevels,
    EOATerrainSettingsTypeVerticalExaggeration,
    EOAGPXSettingsTypeVerticalExaggeration,
    EOAGPXSettingsTypeWallHeight
};

@protocol OATerrainParametersDelegate

- (void)onBackTerrainParameters;

@end

typedef void(^OAControllerActionFloatValueCallback)(CGFloat value);
typedef void(^OAControllerActionIntegerValueCallback)(NSInteger value);
typedef void(^OAControllerHideCallback)();

@interface OAMapSettingsTerrainParametersViewController : OABaseScrollableHudViewController

@property (nonatomic, readonly) EOATerrainSettingsType terrainType;
@property (nonatomic, copy, nullable) OAControllerActionFloatValueCallback applyCallback;
@property (nonatomic, copy, nullable) OAControllerActionIntegerValueCallback applyWallHeightCallback;
@property (nonatomic, copy, nullable) OAControllerHideCallback hideCallback;

- (instancetype)initWithSettingsType:(EOATerrainSettingsType)terrainType;
- (void)configureGPXVerticalExaggerationScale:(CGFloat)scale;
- (void)configureGPXElevationMeters:(NSInteger)meters;

@property (nonatomic, weak) id<OATerrainParametersDelegate> delegate;

@end
