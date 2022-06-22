//
//  OAImportBackupTask.h
//  OsmAnd Maps
//
//  Created by Paul on 09.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAItemProgressInfo : NSObject

- (instancetype) initWithType:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress work:(NSInteger)work finished:(BOOL)finished;

@property (nonatomic, assign) NSInteger work;
@property (nonatomic, assign, readonly) NSInteger value;
@property (nonatomic, assign, readonly) BOOL finished;

@end

@interface OAImportBackupTask : NSOperation

@end

NS_ASSUME_NONNULL_END
