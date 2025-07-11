//
//  OAOBDConnector.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAOBDConnector : NSObject
@property (nonatomic, copy, nullable) void (^disconnectHandler)(void);
@property (nonatomic, copy, nullable) void (^failureHandler)(void);

- (instancetype)initWithIsSimulator:(BOOL)isSimulator;

@end

@interface OAOkioSource : NSObject
@end

@interface OAOkioSink : NSObject
@end

NS_ASSUME_NONNULL_END
