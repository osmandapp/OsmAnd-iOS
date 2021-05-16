//
//  OASettingsExporter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem;

@interface OASettingsExporter : NSObject

- (instancetype) initWithExportParam:(BOOL)exportItemsFiles acceptedExtensions:(NSSet<NSString *> *)extensions;
- (void) addSettingsItem:(OASettingsItem *)item;
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value;
- (void) exportSettings:(NSString *)file error:(NSError * _Nullable *)error;

@end

#pragma mark - OAExportAsyncTask

@interface OAExportAsyncTask : NSObject

@property (weak, nonatomic) id<OASettingsImportExportDelegate> settingsExportDelegate;

- (instancetype) initWithFile:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles extensionsFilter:(NSString *)extensionsFilter;

- (void) execute;

@end

NS_ASSUME_NONNULL_END
