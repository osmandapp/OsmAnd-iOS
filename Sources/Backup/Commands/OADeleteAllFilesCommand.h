//
//  OADeleteAllFilesCommand.h
//  OsmAnd Maps
//
//  Created by Skalii on 23.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseDeleteFilesCommand.h"

@class OAExportSettingsType;

@interface OADeleteAllFilesCommand : OABaseDeleteFilesCommand

- (instancetype)initWithTypes:(NSArray<OAExportSettingsType *> *)types;
- (instancetype)initWithTypes:(NSArray<OAExportSettingsType *> *)types listener:(id<OAOnDeleteFilesListener>)listener;

@end
