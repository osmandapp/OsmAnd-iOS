//
//  OANetworkUtilities.m
//  OsmAnd
//
//  Created by Alexey on 27/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OANetworkUtilities.h"

@implementation OANetworkUtilities

+ (void) sendRequestWithUrl:(NSString *)url params:(NSDictionary<NSString *, NSString *> *)params post:(BOOL)post onComplete:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))onComplete
{
    NSURL *urlObj;
    NSMutableString *paramsStr = nil;
    NSString *paramsSeparator = [url containsString:@"?"] ? @"&" : @"?";
    if (params.count > 0)
    {
        paramsStr = [NSMutableString string];
        [params enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            if (paramsStr.length > 0)
                [paramsStr appendString:@"&"];
            
            [paramsStr appendString:[key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [paramsStr appendString:@"="];
            [paramsStr appendString:[value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
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
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:postData];
    }
    else
    {
        [request setHTTPMethod:@"GET"];
    }
    
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (onComplete)
            onComplete(data, response, error);
    }];
    
    [downloadTask resume];
}

@end
