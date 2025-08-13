//
// Created by Skalii on 25.07.2022.
// Copyright (c) 2022 OsmAnd. All rights reserved.
//

#ifndef OAWeatherWebClient_h
#define OAWeatherWebClient_h

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>
#import "OAAtomicInteger.h"

#include <OsmAndCore/IWebClient.h>

static NSString *kOAWeatherWebClientNotificationKey = @"kOAWeatherWebClientNotificationKey";

class OAWeatherRequestResult : public OsmAnd::IWebClient::IRequestResult
{
private:
    const bool successful;
protected:
public:
    OAWeatherRequestResult(const bool successful = false);
    virtual ~OAWeatherRequestResult();

    virtual bool isSuccessful() const;
};

class OAWeatherHttpRequestResult : public OsmAnd::IWebClient::IHttpRequestResult
{
private:
    const bool successful;
    const unsigned int httpStatusCode;
protected:
public:
    OAWeatherHttpRequestResult(const bool successful = false, const unsigned int httpStatus = 0);
    virtual ~OAWeatherHttpRequestResult();

    virtual bool isSuccessful() const;
    virtual unsigned int getHttpStatusCode() const;
};

class OAWeatherWebClient : public OsmAnd::IWebClient
{
private:
    NSURLSession *_urlSession;
    OAAtomicInteger *_activeRequestsCounter;
protected:
public:
    OAWeatherWebClient();
    virtual ~OAWeatherWebClient();

    virtual QByteArray downloadData(
            const QString& url,
            IWebClient::DataRequest& dataRequest,
            const QString& userAgent = QString()) const;
    virtual QString downloadString(
            const QString& url,
            IWebClient::DataRequest& dataRequest) const;
    virtual long long downloadFile(
            const QString& url,
            const QString& fileName,
            const long long lastTime,
            IWebClient::DataRequest& dataRequest) const;
};

#endif /* OAWeatherWebClient_h */
