//
//  OAExportAsyncTask.h
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"

@interface OAExportAsyncTask : NSObject

@property (weak, nonatomic) id<OASettingsImportExportDelegate> settingsExportDelegate;

- (instancetype) initWithFile:(NSString *)settingsFile items:(NSArray<OASettingsItem *> *)items exportItemFiles:(BOOL)exportItemFiles extensionsFilter:(NSString *)extensionsFilter;

- (void) execute;

@end
