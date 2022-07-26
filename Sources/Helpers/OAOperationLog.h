//
//  OAOperationLog.h
//  OsmAnd Maps
//
//  Created by Paul on 25.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAOperationLog : NSObject

- (instancetype) initWithOperationName:(NSString *)operationName;
- (instancetype) initWithOperationName:(NSString *)operationName debug:(BOOL)debug;
- (instancetype) initWithOperationName:(NSString *)operationName debug:(BOOL)debug logThreshold:(NSTimeInterval)logThreshold;

- (void) startOperation;
- (void) startOperation:(NSString *)message;

- (void) finishOperation;
- (void) finishOperation:(NSString *)message;

- (void) log:(NSString *)message;
- (void) log:(NSString *)message forceLog:(BOOL)forceLog;

@end
