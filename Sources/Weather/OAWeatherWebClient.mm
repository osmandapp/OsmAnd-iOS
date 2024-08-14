//
// Created by Skalii on 25.07.2022.
// Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherWebClient.h"

#define kTimeout 60.0 * 5.0 // 5 minutes

OAWeatherRequestResult::OAWeatherRequestResult(const bool successful) : successful(successful)
{
}

OAWeatherRequestResult::~OAWeatherRequestResult()
{
}

bool OAWeatherRequestResult::isSuccessful() const
{
    return successful;
}


OAWeatherHttpRequestResult::OAWeatherHttpRequestResult(const bool successful, const unsigned int httpStatus) : successful(successful), httpStatusCode(httpStatus)
{
}

OAWeatherHttpRequestResult::~OAWeatherHttpRequestResult()
{
}

bool OAWeatherHttpRequestResult::isSuccessful() const
{
    return successful;
}

unsigned int OAWeatherHttpRequestResult::getHttpStatusCode() const
{
    return httpStatusCode;
}

OAWeatherWebClient::OAWeatherWebClient()
{
    _activeRequestsCounter = [[OAAtomicInteger alloc] initWithInteger:0];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfiguration.timeoutIntervalForRequest = 300.0;
    sessionConfiguration.timeoutIntervalForResource = 600.0;
    sessionConfiguration.HTTPMaximumConnectionsPerHost = 50;
    _urlSession = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                delegate:nil
                                           delegateQueue:[NSOperationQueue mainQueue]];
}

OAWeatherWebClient::~OAWeatherWebClient()
{
}

QByteArray OAWeatherWebClient::downloadData(
        const QString& url,
        IWebClient::DataRequest& dataRequest,
        const QString& userAgent /* = QString()*/) const
{
    return QByteArray();
}

QString OAWeatherWebClient::downloadString(
        const QString& url,
        IWebClient::DataRequest& dataRequest) const
{
    return QString();
}

long long OAWeatherWebClient::downloadFile(
        const QString& url,
        const QString& fileName,
        const long long lastTime,
        IWebClient::DataRequest& dataRequest) const
{
    long long result = -1;
    BOOL success = false;
    if (url != nullptr && !url.isEmpty() && fileName != nullptr && !fileName.isEmpty())
    {
        long long lastModified = 0;
        NSMutableURLRequest *request =
                [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url.toNSString()]
                                    cachePolicy:NSURLRequestReloadIgnoringCacheData
                                    timeoutInterval:kTimeout];

        [request setHTTPMethod:@"HEAD"];
       
        unsigned int responseCode = 0;
        NSURLResponse __block *response = nil;
        NSError __block *error = nil;
        NSData __block *data = nil;

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionDataTask *task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error)
                {
                    [NSNotificationCenter.defaultCenter postNotificationName:kOAWeatherWebClientNotificationKey object:@([_activeRequestsCounter decrementAndGet])];
                    response = _response;
                    error = _error;
                    dispatch_semaphore_signal(semaphore);
                }
        ];
        [NSNotificationCenter.defaultCenter postNotificationName:kOAWeatherWebClientNotificationKey object:@([_activeRequestsCounter incrementAndGet])];
        [task resume];

        if (dataRequest.queryController)
        {
            while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC))))
            {
                if (dataRequest.queryController->isAborted())
                {
                    [task cancel];

                    dataRequest.requestResult.reset(new OAWeatherHttpRequestResult(false, responseCode));

                    return result;
                }
            }
        }
        else
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        if (error)
            return result;
        else if(response && [response isKindOfClass:[NSHTTPURLResponse class]])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
            if ([httpResponse respondsToSelector:@selector(allHeaderFields)]) {
                NSDictionary *headerFields = [httpResponse allHeaderFields];
                NSString *lastModification = [headerFields objectForKey:@"Last-Modified"];

                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
                NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
                [formatter setLocale:locale];
                NSDate *dateTime = [formatter dateFromString:lastModification];
                
                lastModified = (long long) ([dateTime timeIntervalSince1970] * 1000);
            }
            else
                return result;
        }
        else
            return result;
       
        if (lastModified > 0 && lastModified <= lastTime)
            return 0;

        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url.toNSString()]
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData
                                      timeoutInterval:kTimeout];
        
        responseCode = 0;
        response = nil;
        error = nil;

        semaphore = dispatch_semaphore_create(0);
        task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error)
                {
                    [NSNotificationCenter.defaultCenter postNotificationName:kOAWeatherWebClientNotificationKey object:@([_activeRequestsCounter decrementAndGet])];
                    response = _response;
                    data = _data;
                    error = _error;
                    dispatch_semaphore_signal(semaphore);
                }
        ];
        
        [NSNotificationCenter.defaultCenter postNotificationName:kOAWeatherWebClientNotificationKey object:@([_activeRequestsCounter incrementAndGet])];
        [task resume];

        if (dataRequest.queryController)
        {
            while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC))))
            {
                if (dataRequest.queryController->isAborted())
                {
                    [task cancel];

                    dataRequest.requestResult.reset(new OAWeatherHttpRequestResult(false, responseCode));

                    return false;
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
            dataRequest.requestResult.reset(new OAWeatherHttpRequestResult(false, responseCode));

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
        data = nil;

        dataRequest.requestResult.reset(new OAWeatherHttpRequestResult(success, responseCode));

        if (success)
            result = lastModified > 0 ? lastModified : 1;
    }
    return result;
}
