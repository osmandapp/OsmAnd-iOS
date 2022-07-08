//
//  OABackupExporter.h
//  OsmAnd Maps
//
//  Created by Paul on 16.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAItemExporter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OANetworkExportProgressListener <NSObject>

- (void) itemExportStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work;

- (void) updateItemProgress:(NSString *)type fileName:(NSString *)fileName progress:(int)progress;

- (void) itemExportDone:(NSString *)type fileName:(NSString *)fileName;

- (void) updateGeneralProgress:(int)uploadedItems uploadedKb:(int)uploadedKb;

- (void) networkExportDone:(NSDictionary<NSString *, NSString *> *)errors;

@end

@interface OABackupExporter : OAItemExporter

@end

NS_ASSUME_NONNULL_END
