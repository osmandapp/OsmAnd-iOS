//
//  OAProfileSettingsResetHelper.h
//  OsmAnd
//
//  Created by nnngrach on 08.09.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"

@interface OAProfileSettingsResetHelper : NSObject

+ (void) resetProfileSettingsForAppMode:(OAApplicationMode *)appMode;
+ (void) applyReadedSettings:(NSDictionary<NSString *, NSString *> *)settings actor:(OASettingsItemJsonReader *)actor;
+ (void) saveToBackup:(NSDictionary<NSString *, NSString *> *)settings withFilename:(NSString *)filename;
+ (void) restoreFromBackup:(NSString *)filename actor:(OASettingsItemJsonReader *)actor;

@end
