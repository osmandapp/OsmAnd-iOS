//
//  OAAbstractProgress.m
//  OsmAnd Maps
//
//  Created by Paul on 26.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAURLSessionProgress.h"

@implementation OAURLSessionProgress

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    int progress = ((double) totalBytesSent / (double) totalBytesExpectedToSend) * 100;
    _onProgress(progress, bytesSent / 1024);
}

@end
