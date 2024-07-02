//
//  OAColorPaletteHelper.m
//  OsmAnd Maps
//
//  Created by Skalii on 27.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAColorPaletteHelper.h"
#import "OAColorizationType.h"
#import "OARouteColorize.h"
#import "OALog.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAColorPaletteHelper
{
    OsmAndAppInstance _app;
    NSMutableDictionary<NSString *, ColorPalette *> *_cachedColorPalette;
}

+ (OAColorPaletteHelper *)sharedInstance
{
    static OAColorPaletteHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAColorPaletteHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _cachedColorPalette = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSDictionary<NSString *, NSArray *> *)getPalletsForType:(NSInteger)gradientType isTerrainType:(BOOL)isTerrainType
{
    NSMutableDictionary<NSString *, NSArray *> *colorPalettes = [NSMutableDictionary dictionary];
    if (!isTerrainType)
        colorPalettes = [self getColorizationTypePallets:(EOAColorizationType) gradientType];
    else
        colorPalettes = [self getTerrainModePallets:(TerrainType) gradientType];
    return colorPalettes;
}

- (NSMutableDictionary<NSString *, NSArray *> *)getColorizationTypePallets:(EOAColorizationType)type
{
    NSMutableDictionary<NSString *, NSArray *> *colorPalettes = [NSMutableDictionary dictionary];
    NSString *colorTypePrefix = [NSString stringWithFormat:@"route_%@_", [self getColorizationTypeName:type]];
    
    NSArray<NSString *> *colorFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self getColorPaletteDir] error:nil];
    for (NSString *fileName in colorFiles)
    {
        if ([fileName hasPrefix:colorTypePrefix] && [fileName hasSuffix:@".txt"])
        {
            NSString *colorPalletName = [[fileName stringByReplacingOccurrencesOfString:colorTypePrefix withString:@""] stringByReplacingOccurrencesOfString:@".txt" withString:@""];
            ColorPalette *colorPalette = [self getGradientColorPalette:fileName];
            if (colorPalette)
                colorPalettes[colorPalletName] = @[colorPalette, @([[[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil] fileModificationDate].timeIntervalSince1970)];
        }
    }
    return colorPalettes;
}

- (NSMutableDictionary<NSString *, NSArray *> *)getTerrainModePallets:(TerrainType)type
{
    NSMutableDictionary<NSString *, NSArray *> *colorPalettes = [NSMutableDictionary dictionary];
    NSArray<TerrainMode *> *modes = TerrainMode.values;
    for (TerrainMode *mode in modes)
    {
        if (mode.type == type)
        {
            NSString *fileName = [mode getMainFile];
            NSString *filePath = [[self getColorPaletteDir] stringByAppendingPathComponent:fileName];
            ColorPalette *colorPalette = [self getGradientColorPalette:fileName];
            if (colorPalette && [[NSFileManager defaultManager] fileExistsAtPath:filePath])
                colorPalettes[[mode getKeyName]] = @[colorPalette, @([[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileModificationDate].timeIntervalSince1970)];
        }
    }
    return colorPalettes;
}

- (BOOL)isValidPalette:(ColorPalette *)palette
{
    return palette && palette.colorValues.count >= 2;
}

- (NSString *)getColorPaletteDir
{
    return _app.colorsPalettePath;
}

- (ColorPalette *)requireGradientColorPaletteSync:(EOAColorizationType)colorizationType gradientPaletteName:(NSString *)gradientPaletteName
{
    ColorPalette *colorPalette = [self getGradientColorPaletteSync:colorizationType gradientPaletteName:gradientPaletteName];
    return [self isValidPalette:colorPalette] ? colorPalette : [OARouteColorize getDefaultPalette:colorizationType];
}

- (ColorPalette *)getGradientColorPaletteSync:(EOAColorizationType)colorizationType gradientPaletteName:(NSString *)gradientPaletteName
{
    NSString *colorPaletteFileName = [NSString stringWithFormat:@"route_%@_%@.txt", [self getColorizationTypeName:colorizationType], gradientPaletteName];
    return [self getGradientColorPalette:colorPaletteFileName];
}

- (ColorPalette *)getGradientColorPaletteSyncWithModeKey:(NSString *)modeKey
{
    return [self getGradientColorPalette:modeKey];
}

- (ColorPalette *)getGradientColorPalette:(NSString *)colorPaletteFileName
{
    ColorPalette *colorPalette = [_cachedColorPalette objectForKey:colorPaletteFileName];
    if (!colorPalette)
    {
        NSString *filePath = [[self getColorPaletteDir] stringByAppendingPathComponent:colorPaletteFileName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            NSError *error;
            colorPalette = [ColorPalette parseColorPaletteFrom:filePath error:&error];
            if (!error && colorPalette)
                _cachedColorPalette[colorPaletteFileName] = colorPalette;
            else
                OALog([NSString stringWithFormat:@"Error reading color file: %@", error]);
        }
    }
    return colorPalette;
}

- (NSString *)getColorizationTypeName:(EOAColorizationType)type
{
    if (type == EOAColorizationTypeSlope)
        return @"slope";
    else if (type == EOAColorizationTypeSpeed)
        return @"speed";
    else if (type == EOAColorizationTypeElevation)
        return @"elevation";
    return @"none";
}

@end
