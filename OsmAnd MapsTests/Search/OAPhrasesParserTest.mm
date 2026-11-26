#import <XCTest/XCTest.h>
#import "OAPhrasesParser.h"

@interface OAPhrasesParserTest : XCTestCase
@end

@implementation OAPhrasesParserTest

- (void)testPreservesSpaceBetweenTextFragments
{
    // The XML comment forces separate SAX callbacks on either side of the word boundary.
    NSString *xml = @"<resources><string name=\"poi_traffic_signals\">  Dur <!-- -->ışığı  </string></resources>";
    NSURL *url = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSError *error = nil;
    XCTAssertTrue([xml writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error], @"%@", error);

    OAPhrasesParser *parser = [[OAPhrasesParser alloc] init];
    [parser getPhrasesSync:url.path];
    XCTAssertEqualObjects(parser.phrases[@"poi_traffic_signals"], @"Dur ışığı");
    [NSFileManager.defaultManager removeItemAtURL:url error:nil];
}

@end
