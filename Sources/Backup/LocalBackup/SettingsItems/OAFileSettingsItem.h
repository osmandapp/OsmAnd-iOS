//
//  OAFileSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAFileSettingsItemFileSubtype) {
    EOAFileSettingsItemFileSubtypeUnknown = -1,
    EOAFileSettingsItemFileSubtypeOther = 0,
    EOAFileSettingsItemFileSubtypeRoutingConfig,
    EOAFileSettingsItemFileSubtypeRenderingStyle,
    EOAFileSettingsItemFileSubtypeWikiMap,
    EOAFileSettingsItemFileSubtypeSrtmMap,
    EOAFileSettingsItemFileSubtypeTerrainMap,
    EOAFileSettingsItemFileSubtypeNauticalDepth,
    EOAFileSettingsItemFileSubtypeObfMap,
    EOAFileSettingsItemFileSubtypeTilesMap,
    EOAFileSettingsItemFileSubtypeRoadMap,
    EOAFileSettingsItemFileSubtypeGpx,
    EOAFileSettingsItemFileSubtypeVoiceTTS,
    EOAFileSettingsItemFileSubtypeVoice,
    EOAFileSettingsItemFileSubtypeTravel,
    EOAFileSettingsItemFileSubtypeMultimediaNotes,
    EOAFileSettingsItemFileSubtypeFavoritesBackup,
    EOAFileSettingsItemFileSubtypeColorPalette,
    EOAFileSettingsItemFileSubtypesCount
};

@interface OAFileSettingsItemFileSubtype : NSObject

+ (NSString *) getSubtypeName:(EOAFileSettingsItemFileSubtype)subtype;
+ (NSString *) getSubtypeFolder:(EOAFileSettingsItemFileSubtype)subtype;
+ (EOAFileSettingsItemFileSubtype) getSubtypeByName:(NSString *)name;
+ (EOAFileSettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName;
+ (NSString *) getSubtypeFolderName:(EOAFileSettingsItemFileSubtype)subtype;
+ (BOOL) isMap:(EOAFileSettingsItemFileSubtype)type;
+ (NSString *) getIcon:(EOAFileSettingsItemFileSubtype)subtype;

@end

@interface OAFileSettingsItem : OASettingsItem

@property (nonatomic) NSString *filePath;
@property (nonatomic, readonly) EOAFileSettingsItemFileSubtype subtype;
@property (nonatomic, assign) long size;
@property (nonatomic) NSString *md5Digest;

- (nullable instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error;
- (BOOL) exists;
- (NSString *) renameFile:(NSString *)file;
- (NSString *) getPluginPath;
- (void) installItem:(NSString *)destFilePath;
- (NSString *) getIconName;

- (BOOL) needMd5Digest;

@end

@interface OAFileSettingsItemReader : OASettingsItemReader<OAFileSettingsItem *>

@end

@interface OAFileSettingsItemWriter : OASettingsItemWriter<OAFileSettingsItem *>

@end

NS_ASSUME_NONNULL_END
