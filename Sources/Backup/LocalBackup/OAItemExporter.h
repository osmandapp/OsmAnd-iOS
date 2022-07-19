//
//  OAItemExporter.h
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"

@class OAAbstractWriter;

@interface OAItemExporter : NSObject

@property (nonatomic, weak) id<OAExportProgressListener> progressListener;

- (instancetype) initWithListener:(id<OAExportProgressListener>)listener;

- (void) addSettingsItem:(OASettingsItem *)item;
- (void) writeItems:(OAAbstractWriter *)writer;
- (void) doExport;

- (NSArray<OASettingsItem *> *)getItems;
- (BOOL) isCancelled;
- (void) cancel;
- (void) addAdditionalParam:(NSString *)key value:(NSString *)value;

- (NSDictionary *) createItemsJson;

@end
