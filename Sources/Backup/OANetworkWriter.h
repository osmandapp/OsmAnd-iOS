//
//  OANetworkWriter.h
//  OsmAnd Maps
//
//  Created by Paul on 08.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAAbstractWriter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OAOnUploadItemListener <NSObject>

- (void) onItemUploadStarted:(OASettingsItem *)item fileName:(NSString *)fileName work:(NSInteger)work;
- (void) onItemUploadProgress:(OASettingsItem *)item fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork;
- (void) onItemFileUploadDone:(OASettingsItem *)item fileName:(NSString *)fileName uploadTime:(long)uploadTime error:(NSString *)error;
- (void) onItemUploadDone:(OASettingsItem *)item fileName:(NSString *)fileName error:(NSString *)error;

@end

@interface OANetworkWriter : OAAbstractWriter

- (instancetype)initWithListener:(id<OAOnUploadItemListener>)listener;

@end

NS_ASSUME_NONNULL_END
