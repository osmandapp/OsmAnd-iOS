//
//  OAWebClientTests.mm
//  OsmAnd MapsTests
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OAWebClient.h"

@interface OAWebClientTests : XCTestCase
@end

@implementation OAWebClientTests

- (void)testRequestHeadersIncludeUserAgentAndReferer
{
    OAWebClientDataRequest dataRequest;
    dataRequest.headers[QStringLiteral("Referer")] = QStringLiteral("https://nakarte.me/");

    const auto headers = OAWebClient::getRequestHeaders(
        QStringLiteral("Custom User Agent"),
        dataRequest);

    XCTAssertTrue(headers.value(QStringLiteral("User-Agent")) == QStringLiteral("Custom User Agent"));
    XCTAssertTrue(headers.value(QStringLiteral("Referer")) == QStringLiteral("https://nakarte.me/"));
}

- (void)testRequestHeadersOmitEmptyReferer
{
    OAWebClientDataRequest dataRequest;

    const auto headers = OAWebClient::getRequestHeaders(
        QStringLiteral("Custom User Agent"),
        dataRequest);

    XCTAssertTrue(headers.value(QStringLiteral("User-Agent")) == QStringLiteral("Custom User Agent"));
    XCTAssertFalse(headers.contains(QStringLiteral("Referer")));
}

- (void)testRequestHeadersSupportGenericDataRequest
{
    OsmAnd::IWebClient::DataRequest dataRequest;

    const auto headers = OAWebClient::getRequestHeaders(
        QStringLiteral("Custom User Agent"),
        dataRequest);

    XCTAssertTrue(headers.value(QStringLiteral("User-Agent")) == QStringLiteral("Custom User Agent"));
    XCTAssertFalse(headers.contains(QStringLiteral("Referer")));
}

@end
