//
//  OABackupError.h
//  OsmAnd Maps
//
//  Created by Paul on 24.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OABackupError : NSObject

@property (nonatomic, readonly) NSString *error;
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly, assign) NSInteger code;

- (instancetype) initWithError:(NSString *)error;

- (NSString *) getLocalizedError;
- (NSString *) toString;

@end

NS_ASSUME_NONNULL_END
