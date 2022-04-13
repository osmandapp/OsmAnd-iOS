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
    EOASettingsItemFileSubtypeObfMap,
    EOASettingsItemFileSubtypeTilesMap,
    EOASettingsItemFileSubtypeRoadMap,
    EOASettingsItemFileSubtypeGpx,
    EOASettingsItemFileSubtypeVoice,
    EOASettingsItemFileSubtypeVoiceTTS,
    EOASettingsItemFileSubtypeTravel,
//    EOASettingsItemFileSubtypeMultimediaFile,
    EOASettingsItemFileSubtypesCount
};

@interface OAFileSettingsItemFileSubtype : NSObject

+ (NSString *) getSubtypeName:(EOASettingsItemFileSubtype)subtype;
+ (NSString *) getSubtypeFolder:(EOASettingsItemFileSubtype)subtype;
+ (EOASettingsItemFileSubtype) getSubtypeByName:(NSString *)name;
+ (EOASettingsItemFileSubtype) getSubtypeByFileName:(NSString *)fileName;
+ (BOOL) isMap:(EOASettingsItemFileSubtype)type;
+ (NSString *) getIcon:(EOASettingsItemFileSubtype)subtype;

@end

@interface OAFileSettingsItem : OASettingsItem

@property (nonatomic, readonly) NSString *filePath;
@property (nonatomic, readonly) EOASettingsItemFileSubtype subtype;

- (instancetype _Nullable) initWithFilePath:(NSString *)filePath error:(NSError * _Nullable *)error;
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
