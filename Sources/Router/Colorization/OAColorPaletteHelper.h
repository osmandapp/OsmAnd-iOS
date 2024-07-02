//
//  OAColorPaletteHelper.h
//  OsmAnd
//
//  Created by Skalii on 27.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAColorizationType.h"

@class ColorPalette;

@interface OAColorPaletteHelper : NSObject

+ (OAColorPaletteHelper *)sharedInstance;

- (NSDictionary<NSString *, NSArray *> *)getPalletsForType:(NSInteger)gradientType isTerrainType:(BOOL)isTerrainType;
- (ColorPalette *)requireGradientColorPaletteSync:(EOAColorizationType)colorizationType gradientPaletteName:(NSString *)gradientPaletteName;
- (ColorPalette *)getGradientColorPaletteSync:(EOAColorizationType)colorizationType gradientPaletteName:(NSString *)gradientPaletteName;
- (ColorPalette *)getGradientColorPaletteSync:(EOAColorizationType)colorizationType
                          gradientPaletteName:(NSString *)gradientPaletteName
                                      refresh:(BOOL)refresh;
- (ColorPalette *)getGradientColorPaletteSyncWithModeKey:(NSString *)modeKey;
- (ColorPalette *)getGradientColorPalette:(NSString *)colorPaletteFileName;

@end
