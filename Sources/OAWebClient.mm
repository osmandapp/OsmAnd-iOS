//
//  OAWebClient.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#include "OAWebClient.h"


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
                                     std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult,
                                     const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback) const
{
    QByteArray res;
    if (url != nullptr && !url.isEmpty())
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:
                                 [NSURL URLWithString:url.toNSString()]];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&response
                                                         error:&error];
        
        unsigned int responseCode = 0;
        if (response && [response isKindOfClass:[NSHTTPURLResponse class]])
        {
            responseCode = (unsigned int) ((NSHTTPURLResponse *) response).statusCode;
        }
        
        if (!response || error)
        {
            if (requestResult != nullptr)
            {
                requestResult->reset(new OAHttpRequestResult(false, responseCode));
            }
            return QByteArray();
        }
        
        res = QByteArray::fromNSData(data);
        
        if (requestResult != nullptr)
        {
            requestResult->reset(new OAHttpRequestResult(true, responseCode));
        }
    }
    return res;
}

QString OAWebClient::downloadString(
                                    const QString& url,
                                    std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult,
                                    const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback) const
{
    if (url != nullptr && !url.isEmpty())
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:
                                 [NSURL URLWithString:url.toNSString()]];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:&response
                                                         error:&error];
        
        QString charset = QString::null;
        unsigned int responseCode = 0;
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
            if (requestResult != nullptr)
            {
                requestResult->reset(new OAHttpRequestResult(false, responseCode));
            }
            return QString::null;
        }
        
        if (requestResult != nullptr)
        {
            requestResult->reset(new OAHttpRequestResult(true, responseCode));
        }
        
        if (!charset.isNull() && charset.contains(QLatin1String("utf-8")))
            return QString::fromUtf8(QByteArray::fromNSData(data));
        return QString::fromLocal8Bit(QByteArray::fromNSData(data));
    }
    return QString::null;
}

bool OAWebClient::downloadFile(
                               const QString& url,
                               const QString& fileName,
                               std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult,
                               const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback) const
{
    BOOL success = false;
    if (url != nullptr && !url.isEmpty() && fileName != nullptr && !fileName.isEmpty())
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:
                                 [NSURL URLWithString:url.toNSString()]];
        
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
        
        unsigned int responseCode = 0;
        if (response && [response isKindOfClass:[NSHTTPURLResponse class]])
        {
            responseCode = (unsigned int) ((NSHTTPURLResponse *) response).statusCode;
        }

        if (!response || error)
        {
            if (requestResult != nullptr)
            {
                requestResult->reset(new OAHttpRequestResult(false, responseCode));
            }
            return false;
        }

        NSString *name = fileName.toNSString();
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:[name stringByDeletingLastPathComponent]])
        {
            success = [manager createDirectoryAtPath:[name stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        else
        {
            success = YES;
        }
        
        if (success)
        {
            success = [data writeToFile:name atomically:YES];
        }
        
        if (requestResult != nullptr)
        {
            requestResult->reset(new OAHttpRequestResult(success, responseCode));
        }
    }
    return success;
}

