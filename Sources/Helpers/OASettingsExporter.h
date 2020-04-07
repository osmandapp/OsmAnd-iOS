//
//  OASettingsExporter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"

@class OASettingsItem;

@interface OASettingsExporter : NSObject

- (instancetype) init;
- (void) addSettingsItem:(OASettingsItem*)item;
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value;
- (void) exportSettings:(NSString *)file;

@end

#pragma mark - OAExportAsyncTask

@interface OAExportAsyncTask : NSObject

- (instancetype) initWith:(NSString *)settingsFile listener:(OASettingsExport*)listener items:(NSMutableArray<OASettingsItem *>*)items;
- (void) executeParameters;

@end
