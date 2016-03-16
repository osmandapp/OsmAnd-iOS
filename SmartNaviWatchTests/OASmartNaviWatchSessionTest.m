//
//  OASmartNaviWatchSessionTest.m
//  OsmAnd
//
//  Created by egloff on 04/02/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OASmartNaviWatchSession.h"

@interface OASmartNaviWatchSessionTest : XCTestCase

@end

@implementation OASmartNaviWatchSessionTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testIfPluginEnabled {
    
    XCTAssertTrue([[OASmartNaviWatchSession sharedInstance] checkIfPluginEnabled]);
    
}


-(void)testActivatePlugin {
    WCSession* session = [WCSession defaultSession];
    session.delegate = nil;
    
    [[OASmartNaviWatchSession sharedInstance] activatePlugin];
    XCTAssertNotNil(session.delegate);


}

-(void)testDeactivatePlugin {
    
    WCSession* session = [WCSession defaultSession];
    session.delegate = @"mockObject";
    
    [[OASmartNaviWatchSession sharedInstance] deactivatePlugin];
    XCTAssertNil(session.delegate);
}

@end
