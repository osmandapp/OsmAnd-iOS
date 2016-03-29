//
//  OAWebClient.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/03/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#ifndef OAWebClient_h
#define OAWebClient_h

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/IWebClient.h>


class OARequestResult : public OsmAnd::IWebClient::IRequestResult
{
private:
    const bool successful;
protected:
public:
    OARequestResult(const bool successful = false);
    virtual ~OARequestResult();
    
    virtual bool isSuccessful() const;
};

class OAHttpRequestResult : public OsmAnd::IWebClient::IHttpRequestResult
{
private:
    const bool successful;
    const unsigned int httpStatusCode;
protected:
public:
    OAHttpRequestResult(const bool successful = false, const unsigned int httpStatus = 0);
    virtual ~OAHttpRequestResult();
    
    virtual bool isSuccessful() const;
    virtual unsigned int getHttpStatusCode() const;
};



class OAWebClient : public OsmAnd::IWebClient
{
private:
protected:
public:
    OAWebClient();
    virtual ~OAWebClient();
    
    virtual QByteArray downloadData(
                                    const QString& url,
                                    std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult = nullptr,
                                    const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback = nullptr) const;
    virtual QString downloadString(
                                   const QString& url,
                                   std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult = nullptr,
                                   const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback = nullptr) const;
    virtual bool downloadFile(
                              const QString& url,
                              const QString& fileName,
                              std::shared_ptr<const OsmAnd::IWebClient::IRequestResult>* const requestResult = nullptr,
                              const OsmAnd::IWebClient::RequestProgressCallbackSignature progressCallback = nullptr) const;
};


#endif /* OAWebClient_h */
