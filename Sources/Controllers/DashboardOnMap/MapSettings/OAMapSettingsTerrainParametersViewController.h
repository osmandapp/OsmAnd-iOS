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
    EOAGPXSettingsTypeVerticalExaggeration
    
};

@protocol OATerrainParametersDelegate

- (void)onBackTerrainParameters;

@end

@interface OAMapSettingsTerrainParametersViewController : OABaseScrollableHudViewController

@property (nonatomic, readonly) EOATerrainSettingsType terrainType;

- (instancetype)initWithSettingsType:(EOATerrainSettingsType)terrainType;

@property (nonatomic, weak) id<OATerrainParametersDelegate> delegate;

@end
