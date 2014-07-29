//
//  OsmAndAppPrivateProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OsmAndAppPrivateProtocol <NSObject>
@required

- (void)onApplicationWillResignActive;
- (void)onApplicationDidEnterBackground;
- (void)onApplicationWillEnterForeground;
- (void)onApplicationDidBecomeActive;

@end
