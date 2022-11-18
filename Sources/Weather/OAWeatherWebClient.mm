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
        std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult/* = nullptr*/,
        const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback/* = nullptr*/,
        const std::shared_ptr<const OsmAnd::IQueryController>& queryController/* = nullptr*/,
        const QString& userAgent /* = QString()*/) const
{
    return QByteArray();
}

QString OAWeatherWebClient::downloadString(
        const QString& url,
        std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult/* = nullptr*/,
        const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback/* = nullptr*/,
        const std::shared_ptr<const OsmAnd::IQueryController>& queryController/* = nullptr*/) const
{
    return QString();
}

bool OAWeatherWebClient::downloadFile(
        const QString& url,
        const QString& fileName,
        std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult/* = nullptr*/,
        const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback/* = nullptr*/,
        const std::shared_ptr<const OsmAnd::IQueryController>& queryController/* = nullptr*/) const
{
    BOOL success = false;
    if (url != nullptr && !url.isEmpty() && fileName != nullptr && !fileName.isEmpty())
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url.toNSString()]
                                                 cachePolicy:NSURLRequestReloadIgnoringCacheData
                                             timeoutInterval:kTimeout];

        unsigned int responseCode = 0;
        NSURLResponse __block *response = nil;
        NSError __block *error = nil;
        NSData __block *data = nil;

        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionDataTask *task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData *_data, NSURLResponse *_response, NSError *_error)
                {
                    response = _response;
                    data = _data;
                    error = _error;
                    dispatch_semaphore_signal(semaphore);
                }
        ];
        [task resume];

        if (queryController)
        {
            while (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC))))
            {
                if (queryController->isAborted())
                {
                    [task cancel];

                    if (requestResult != nullptr)
                        requestResult->reset(new OAWeatherHttpRequestResult(false, responseCode));

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
            if (requestResult != nullptr)
                requestResult->reset(new OAWeatherHttpRequestResult(false, responseCode));

            return false;
        }

        NSString *name = fileName.toNSString();
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:[name stringByDeletingLastPathComponent]])
            success = [manager createDirectoryAtPath:[name stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        else
            success = YES;

        if (success)
            success = [data writeToFile:name atomically:YES];

        if (requestResult != nullptr)
            requestResult->reset(new OAWeatherHttpRequestResult(success, responseCode));
    }
    return success;
}
