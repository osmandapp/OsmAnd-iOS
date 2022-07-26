//
//  OASettingsExporter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 07.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"
#import "OAItemExporter.h"

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem;

@interface OASettingsExporter : OAItemExporter

- (instancetype) initWithExportParam:(BOOL)exportItemsFiles acceptedExtensions:(NSSet<NSString *> *)extensions;
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value;
- (void) exportSettings:(NSString *)file error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
