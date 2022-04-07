//
//  OARegisterUserCommand.h
//  OsmAnd Maps
//
//  Created by Paul on 24.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OARegisterUserCommand : NSOperation

- (instancetype) initWithEmail:(NSString *)email promoCode:(NSString *)promoCode login:(BOOL)login;

@end

NS_ASSUME_NONNULL_END
