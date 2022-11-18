//
// Created by Skalii on 25.07.2022.
// Copyright (c) 2022 OsmAnd. All rights reserved.
//

#ifndef OAWeatherWebClient_h
#define OAWeatherWebClient_h

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/IWebClient.h>


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
protected:
public:
    OAWeatherWebClient();
    virtual ~OAWeatherWebClient();

    virtual QByteArray downloadData(
            const QString& url,
            std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult = nullptr,
            const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback = nullptr,
            const std::shared_ptr<const OsmAnd::IQueryController>& queryController = nullptr,
            const QString& userAgent = QString()) const;
    virtual QString downloadString(
            const QString& url,
            std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult = nullptr,
            const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback = nullptr,
            const std::shared_ptr<const OsmAnd::IQueryController>& queryController = nullptr) const;
    virtual bool downloadFile(
            const QString& url,
            const QString& fileName,
            std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult = nullptr,
            const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback = nullptr,
            const std::shared_ptr<const OsmAnd::IQueryController>& queryController = nullptr) const;
};

#endif /* OAWeatherWebClient_h */
