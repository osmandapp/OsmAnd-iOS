//
//  OANetworkUtilities.h
//  OsmAnd
//
//  Created by Alexey on 27/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OANetworkUtilities : NSObject

+ (void) sendRequestWithUrl:(NSString *)url params:(NSDictionary<NSString *, NSString *> *)params post:(BOOL)post onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

+ (NSURLSessionDataTask *)createDownloadTask:(NSString *)url
                                      params:(NSDictionary<NSString *, NSString *> *)params
                                        post:(BOOL)post
                                        size:(BOOL)size
                                  onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

@end

NS_ASSUME_NONNULL_END
