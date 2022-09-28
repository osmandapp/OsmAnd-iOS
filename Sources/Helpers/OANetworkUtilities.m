//
//  OANetworkUtilities.m
//  OsmAnd
//
//  Created by Alexey on 27/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OANetworkUtilities.h"
#import "OAUtilities.h"
#import "OAURLSessionProgress.h"

#define BOUNDARY @"CowMooCowMooCowCowCow"

@implementation OANetworkRequest

@end

@implementation OANetworkUtilities

+ (void) sendRequest:(OANetworkRequest *)request async:(BOOL)async onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    [self sendRequestWithUrl:request.url params:request.params post:request.post async:async onComplete:onComplete];
}

+ (void) sendRequestWithUrl:(NSString *)url params:(NSDictionary<NSString *, NSString *> *)params post:(BOOL)post onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    [self sendRequestWithUrl:url params:params post:post async:YES onComplete:onComplete];
}

+ (void) sendRequestWithUrl:(NSString *)url params:(NSDictionary<NSString *, NSString *> *)params post:(BOOL)post async:(BOOL)async onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *urlObj;
    NSMutableString *paramsStr = nil;
    NSString *paramsSeparator = [url containsString:@"?"] ? @"&" : @"?";
    if (params.count > 0)
    {
        paramsStr = [NSMutableString string];
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            if (paramsStr.length > 0)
                [paramsStr appendString:@"&"];
            
            [paramsStr appendString:[key escapeUrl]];
            [paramsStr appendString:@"="];
            [paramsStr appendString:[value escapeUrl]];
        }];
    }
    if (post || !paramsStr)
        urlObj = [NSURL URLWithString:url];
    else
        urlObj = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", url, paramsSeparator, paramsStr]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    
    [request addValue:@"UTF-8" forHTTPHeaderField:@"Accept-Charset"];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    if (post && paramsStr)
    {
        NSData *postData = [paramsStr dataUsingEncoding:NSUTF8StringEncoding];
        [request addValue:@"application/x-www-form-urlencoded;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@(postData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:postData];
    }
    else
    {
        [request setHTTPMethod:@"GET"];
    }
    [request setTimeoutInterval:100];
    __block BOOL hasFinished = NO;
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        hasFinished = YES;
        if (onComplete)
            onComplete(data, response, error);
        if (!async)
            dispatch_semaphore_signal(semaphore);
    }];
    [downloadTask resume];
    if (!hasFinished && !async)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

+ (void) uploadFile:(NSString *)url fileName:(NSString *)fileName params:(NSDictionary<NSString *, NSString *> *)params headers:(NSDictionary<NSString *, NSString *> *)headers data:(NSData *)data gzip:(BOOL)gzip progress:(OAURLSessionProgress *)progress onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *urlObj;
    NSMutableString *paramsStr = nil;
    NSString *paramsSeparator = [url containsString:@"?"] ? @"&" : @"?";
    if (params.count > 0)
    {
        paramsStr = [NSMutableString string];
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            if (paramsStr.length > 0)
                [paramsStr appendString:@"&"];

            [paramsStr appendString:[key escapeUrl]];
            [paramsStr appendString:@"="];
            [paramsStr appendString:[value escapeUrl]];
        }];
    }
    if (!paramsStr)
        urlObj = [NSURL URLWithString:url];
    else
        urlObj = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", url, paramsSeparator, paramsStr]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];

    [request setHTTPMethod:@"POST"];
    [request addValue:[@"multipart/form-data; boundary=" stringByAppendingString:BOUNDARY] forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    [request setTimeoutInterval:1000];
    if (headers)
    {
        [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            [request addValue:obj forHTTPHeaderField:key];
        }];
    }
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    if (gzip)
        fileName = [fileName stringByAppendingPathExtension:@"gz"];
    [postData appendData:[[NSString stringWithFormat:@"content-disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:data];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPBody:postData];

    __block BOOL hasFinished = NO;
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:progress delegateQueue:nil];
    NSURLSessionDataTask *uploadTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        hasFinished = YES;
        if (onComplete)
            onComplete(data, response, error);
        dispatch_semaphore_signal(semaphore);
    }];
    // TODO: add progress
//    uploadTask.progress addObserver: forKeyPath: options: context:

    [uploadTask resume];
    if (!hasFinished)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}


@end
