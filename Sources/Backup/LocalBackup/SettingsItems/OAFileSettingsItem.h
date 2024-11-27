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

typedef NS_ENUM(NSInteger, EOASettingsItemFileSubtype) {
    EOASettingsItemFileSubtypeUnknown = -1,
    EOASettingsItemFileSubtypeOther = 0,
    EOASettingsItemFileSubtypeRoutingConfig,
    EOASettingsItemFileSubtypeRenderingStyle,
    EOASettingsItemFileSubtypeWikiMap,
    EOASettingsItemFileSubtypeSrtmMap,
    EOASettingsItemFileSubtypeTerrainData,
    EOASettingsItemFileSubtypeObfMap,
    EOASettingsItemFileSubtypeTilesMap,
    EOASettingsItemFileSubtypeRoadMap,
    EOASettingsItemFileSubtypeGpx,
    EOASettingsItemFileSubtypeTTSVoice,
    EOASettingsItemFileSubtypeVoice,
    EOASettingsItemFileSubtypeTravel,
//    EOASettingsItemFileSubtypeMultimediaNotes,
    EOASettingsItemFileSubtypeNauticalDepth,
//    EOASettingsItemFileSubtypeFavoritesBackup,
    EOASettingsItemFileSubtypeColorPalette,
    EOASettingsItemFileSubtypesCount
};

@interface OAFileSettingsItemFileSubtype : NSObject

+ (NSString *) getSubtypeName:(EOASettingsItemFileSubtype)subtype;
+ (NSString *) getSubtypeFolder:(EOASettingsItemFileSubtype)subtype;
+ (EOASettingsItemFileSubtype) getSubtypeByName:(NSString *)name;
+ (EOASettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName;
+ (NSString *) getSubtypeFolderName:(EOASettingsItemFileSubtype)subtype;
+ (BOOL) isMap:(EOASettingsItemFileSubtype)type;
+ (NSString *) getIcon:(EOASettingsItemFileSubtype)subtype;

@end

@interface OAFileSettingsItem : OASettingsItem

@property (nonatomic) NSString *filePath;
@property (nonatomic, readonly) EOASettingsItemFileSubtype subtype;
@property (nonatomic, assign) long size;
@property (nonatomic) NSString *md5Digest;

- (nullable instancetype) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error;
- (BOOL) exists;
- (NSString *) renameFile:(NSString *)file;
- (NSString *) getPluginPath;
- (void) installItem:(NSString *)destFilePath;
- (NSString *) getIconName;
- (NSUInteger) getSize;

- (BOOL) needMd5Digest;

@end

@interface OAFileSettingsItemReader : OASettingsItemReader<OAFileSettingsItem *>

@end

@interface OAFileSettingsItemWriter : OASettingsItemWriter<OAFileSettingsItem *>

@end

NS_ASSUME_NONNULL_END
