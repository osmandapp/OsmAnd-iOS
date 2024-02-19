//
//  OANetworkUtilities.h
//  OsmAnd
//
//  Created by Alexey on 27/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAURLSessionProgress;

@interface OANetworkRequest : NSObject

@property (nonatomic) NSString *url;
@property (nonatomic) NSDictionary<NSString *, NSString *> *params;
@property (nonatomic) NSString *userOperation;
@property (nonatomic, assign) BOOL post;

@end

@interface OANetworkUtilities : NSObject

+ (void) sendRequest:(OANetworkRequest *)request
               async:(BOOL)async
          onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

+ (void) sendRequestWithUrl:(NSString *)url
                     params:(NSDictionary<NSString *, NSString *> *)params
                       post:(BOOL)post
                 onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

+ (void) sendRequestWithUrl:(NSString *)url
                     params:(NSDictionary<NSString *, NSString *> *)params
                       post:(BOOL)post
                      async:(BOOL)async
                 onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

+ (void) sendRequestWithUrl:(NSString *)url
                     params:(NSDictionary<NSString *, NSString *> *)params
                       body:(NSString * _Nullable)body
                       post:(BOOL)post
                      async:(BOOL)async
                 onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

+ (void) uploadFile:(NSString *)url fileName:(NSString *)fileName params:(NSDictionary<NSString *, NSString *> *)params headers:(NSDictionary<NSString *, NSString *> *)headers data:(NSData *)data gzip:(BOOL)gzip autorizationHeader:(NSString *)autorizationHeader progress:(OAURLSessionProgress *)progress onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete;

+ (BOOL) downloadFile:(NSString *)fileName url:(NSString *)url progress:(OAURLSessionProgress *)progress;

@end

NS_ASSUME_NONNULL_END
