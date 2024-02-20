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

#define kTimeout 60.0 * 5.0 // 5 minutes

#define BOUNDARY @"CowMooCowMooCowCowCow"

@implementation OANetworkRequest

@end

@implementation OANetworkUtilities

+ (void) sendRequest:(OANetworkRequest *)request
               async:(BOOL)async
          onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    [self sendRequestWithUrl:request.url params:request.params post:request.post async:async onComplete:onComplete];
}

+ (void) sendRequestWithUrl:(NSString *)url
                     params:(NSDictionary<NSString *, NSString *> *)params
                       post:(BOOL)post
                 onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    [self sendRequestWithUrl:url params:params post:post async:YES onComplete:onComplete];
}

+ (void) sendRequestWithUrl:(NSString *)url
                     params:(NSDictionary<NSString *, NSString *> *)params
                       post:(BOOL)post
                      async:(BOOL)async
                 onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    [self sendRequestWithUrl:url
                      params:params
                        body:nil
                 contentType:@"application/x-www-form-urlencoded;charset=UTF-8"
                        post:post
                       async:YES
                  onComplete:onComplete];
}

+ (void) sendRequestWithUrl:(NSString *)url
                     params:(NSDictionary<NSString *, NSString *> *)params
                       body:(NSString *)body
                contentType:(NSString *)contentType
                       post:(BOOL)post
                      async:(BOOL)async
                 onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURL *urlObj;
    NSMutableString *paramsStr = nil;
    NSString *paramsSeparator = [url containsString:@"?"] ? @"&" : @"?";
    if (params && params.count > 0)
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
    if ((post && !body) || !paramsStr)
        urlObj = [NSURL URLWithString:url];
    else
        urlObj = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", url, paramsSeparator, paramsStr]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    
    [request addValue:@"UTF-8" forHTTPHeaderField:@"Accept-Charset"];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    if (post && (paramsStr || body))
    {
        [request setHTTPMethod:@"POST"];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        NSString *httpBody = body ? body : paramsStr;
        NSData *httpBodyData = [httpBody dataUsingEncoding:NSUTF8StringEncoding];
        [request addValue:@(httpBodyData.length).stringValue forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:httpBodyData];
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

+ (void) uploadFile:(NSString *)url fileName:(NSString *)fileName params:(NSDictionary<NSString *, NSString *> *)params headers:(NSDictionary<NSString *, NSString *> *)headers data:(NSData *)data gzip:(BOOL)gzip autorizationHeader:(NSString *)autorizationHeader progress:(OAURLSessionProgress *)progress onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
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
    if (autorizationHeader)
        [request addValue:autorizationHeader forHTTPHeaderField:@"Authorization"];
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", BOUNDARY] dataUsingEncoding:NSUTF8StringEncoding]];
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

    [uploadTask resume];
    if (!hasFinished)
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

+ (BOOL) downloadFile:(NSString *)fileName url:(NSString *)url progress:(OAURLSessionProgress *)progress
{
    BOOL success = NO;
    if (url != nil && url.length > 0 && fileName != nil && fileName.length > 0)
    {
        NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kTimeout];
        
        NSError __block *error = nil;
        NSData __block *data = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        [progress setOnDownloadFinish:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
            data = [NSData dataWithContentsOfURL:location];
            dispatch_semaphore_signal(semaphore);
        }];
        
        [progress setOnDownloadError:^(NSError *_error) {
            error = _error;
            dispatch_semaphore_signal(semaphore);
        }];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:progress delegateQueue:nil];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request];
        [task resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        [session finishTasksAndInvalidate];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:[fileName stringByDeletingLastPathComponent]])
            success = [manager createDirectoryAtPath:[fileName stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        else
            success = YES;
        
        if (success)
            success = [data writeToFile:fileName atomically:YES];
    }
    return success;
}

@end
