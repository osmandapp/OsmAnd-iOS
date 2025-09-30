//
//  OAMapillaryOsmTagHelper.h
//  OsmAnd
//
//  Created by Skalii on 21.02.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapillaryOsmTagHelper : NSObject

+ (void)downloadImageByKey:(NSString *)key
                   session:(nullable NSURLSession *)session
          onDataDownloaded:(void (^)(NSDictionary *data))onDataDownloaded;

@end

NS_ASSUME_NONNULL_END
