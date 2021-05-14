//
//  OAJsonHelper.h
//  OsmAnd
//
//  Created by Paul on 15.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAJsonHelper : NSObject

+ (NSString *) getLocalizedResFromMap:(NSDictionary<NSString *, NSString *> *)localizedMap defValue:(NSString * _Nullable)defValule;

@end

NS_ASSUME_NONNULL_END
