//
//  main.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAAppDelegate.h"
#import "StartupLogging.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        LogStartupSimple(@"App Started (main.m)");
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([OAAppDelegate class]));
    }
}
