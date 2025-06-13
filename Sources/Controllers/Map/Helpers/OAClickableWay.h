//
//  OAClickableWay.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN


@interface OAClickableWay : NSObject

@property (nonatomic) long long osmId;

- (NSString *)getGpxFileName;

@end


NS_ASSUME_NONNULL_END
