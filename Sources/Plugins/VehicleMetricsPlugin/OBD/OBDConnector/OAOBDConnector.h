//
//  OAOBDConnector.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAOBDConnector : NSObject
@property (nonatomic, copy, nullable) void (^disconnectHandler)(void);
@property (nonatomic, copy, nullable) void (^failureHandler)(void);

@end

@interface OAOkioSource : NSObject
@end

@interface OAOkioSink : NSObject
@end
