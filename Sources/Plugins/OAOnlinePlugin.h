//
//  OAOnlinePlugin.h
//  OsmAnd Maps
//
//  Created by Alexey K on 31.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OACustomPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAOnlinePlugin : OACustomPlugin

@property (nonatomic, readonly) NSString *osfUrl;
@property (nonatomic, readonly) NSString *publishedDate;

- (instancetype) initWithJson:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
