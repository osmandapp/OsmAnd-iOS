//
//  OAWebClient.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAWebClient.h"
#import "OAAppVersion.h"

#define kTimeout 60.0 * 5.0 // 5 minutes
#define kDefaultUserAgent @"OsmAndiOS"

OARequestResult::OARequestResult(const bool successful) : successful(successful)
{
}

OARequestResult::~OARequestResult()
{
}

bool OARequestResult::isSuccessful() const
{
    return successful;
}


OAHttpRequestResult::OAHttpRequestResult(const bool successful, const unsigned int httpStatus) : successful(successful), httpStatusCode(httpStatus)
{
}

OAHttpRequestResult::~OAHttpRequestResult()
{
}

bool OAHttpRequestResult::isSuccessful() const
{
    return successful;
}

unsigned int OAHttpRequestResult::getHttpStatusCode() const
{
    return httpStatusCode;
}



OAWebClient::OAWebClient()
{
}

OAWebClient::~OAWebClient()
{
}

QByteArray OAWebClient::downloadData(
    const QString& url,
    IWebClient::DataRequest& dataRequest,
    const QString& userAgent /* QString()*/) const
{
    QByteArray res;
    if (url != nullptr && !url.isEmpty())
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[url.toNSString() stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kTimeout];
        [request addValue:(userAgent.isNull() || userAgent.isEmpty()) ? OAAppVersion.getVersionForUrl : userAgent.toNSString() forHTTPHeaderField:@"User-Agent"];

        unsigned int responseCode = 0;
        NSURLResponse __block *response = nil;
        NSError __block *error = nil;
        NSData __block *data = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error) {
            response = _response;
            data = _data;
            error = _error;
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        
        if (dataRequest.queryController)
        {
            while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC))))
            {
                if (dataRequest.queryController->isAborted())
                {
                    [task cancel];

                    dataRequest.requestResult.reset(new OAHttpRequestResult(false, responseCode));

                    return QByteArray();
                }
            }
        }
        else
        {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
        if (response && [response isKindOfClass:[NSHTTPURLResponse class]])
            responseCode = (unsigned int) ((NSHTTPURLResponse *) response).statusCode;
        
        if (!response || error)
        {
            dataRequest.requestResult.reset(new OAHttpRequestResult(false, responseCode));

            return QByteArray();
        }
        
        res = QByteArray::fromNSData(data);

        dataRequest.requestResult.reset(new OAHttpRequestResult(true, responseCode));
    }
    return res;
}

QString OAWebClient::downloadString(
    const QString& url,
    IWebClient::DataRequest& dataRequest) const
{
    if (url != nullptr && !url.isEmpty())
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:
                                 [NSURL URLWithString:url.toNSString()] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kTimeout];

        unsigned int responseCode = 0;
        NSURLResponse __block *response = nil;
        NSError __block *error = nil;
        NSData __block *data = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error) {
            response = _response;
            data = _data;
            error = _error;
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        
        if (dataRequest.queryController)
        {
            while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC))))
            {
                if (dataRequest.queryController->isAborted())
                {
                    [task cancel];
                    
                    dataRequest.requestResult.reset(new OAHttpRequestResult(false, responseCode));

                    return QString();
                }
            }
        }
        else
        {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
        QString charset = QString();
        if (response && [response isKindOfClass:[NSHTTPURLResponse class]])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            responseCode = (unsigned int) httpResponse.statusCode;
            
            id contentType = [httpResponse.allHeaderFields objectForKey:@"Content-Type"];
            if (contentType)
            {
                NSArray *params = [((NSString *) contentType) componentsSeparatedByString:@";"];
                for (NSString *p in params)
                {
                    NSString *trimmed = [[p stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
                    if ([[trimmed substringToIndex:8] isEqualToString:@"charset="])
                    {
                        charset = QString::fromNSString([[trimmed substringFromIndex:8] lowercaseString]);
                        break;
                    }
                }
            }
        }
        
        if (!response || error)
        {
            dataRequest.requestResult.reset(new OAHttpRequestResult(false, responseCode));

            return QString();
        }
        
        dataRequest.requestResult.reset(new OAHttpRequestResult(true, responseCode));
        
        if (!charset.isNull() && charset.contains(QLatin1String("utf-8")))
            return QString::fromUtf8(QByteArray::fromNSData(data));

        return QString::fromLocal8Bit(QByteArray::fromNSData(data));
    }
    return QString();
}

long long OAWebClient::downloadFile(
    const QString& url,
    const QString& fileName,
    const long long lastTime,
    IWebClient::DataRequest& dataRequest) const
{
    long long result = -1;
    BOOL success = false;
    if (url != nullptr && !url.isEmpty() && fileName != nullptr && !fileName.isEmpty())
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:
                                 [NSURL URLWithString:url.toNSString()] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kTimeout];

        unsigned int responseCode = 0;
        NSURLResponse __block *response = nil;
        NSError __block *error = nil;
        NSData __block *data = nil;
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:nil];
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error) {
            response = _response;
            data = _data;
            error = _error;
            dispatch_semaphore_signal(semaphore);
        }];
        [task resume];
        
        if (dataRequest.queryController)
        {
            while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC))))
            {
                if (dataRequest.queryController->isAborted())
                {
                    [task cancel];

                    dataRequest.requestResult.reset(new OAHttpRequestResult(false, responseCode));

                    return result;
                }
            }
        }
        else
        {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        
        if (response && [response isKindOfClass:[NSHTTPURLResponse class]])
            responseCode = (unsigned int) ((NSHTTPURLResponse *) response).statusCode;

        if (!response || error)
        {
            dataRequest.requestResult.reset(new OAHttpRequestResult(false, responseCode));

            return result;
        }

        NSString *name = fileName.toNSString();
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:[name stringByDeletingLastPathComponent]])
            success = [manager createDirectoryAtPath:[name stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        else
            success = YES;
        
        if (success)
            success = [data writeToFile:name atomically:YES];
        
        dataRequest.requestResult.reset(new OAHttpRequestResult(success, responseCode));
        
        if (success)
            result = 1;
    }
    return result;
}
