//
//  OAOsmBugsRemoteUtil.h
//  OsmAnd
//
//  Created by Paul on 2/9/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OsmBugsRemoteUtil.java
//  git revision f5f971874f8bffbb6471d905f699874519957f4f

#import <Foundation/Foundation.h>
#import "OAOsmPoint.h"
#import "OAOsmBugsUtilsProtocol.h";

@class OAOsmNotePoint, OAOsmBugResult;

NS_ASSUME_NONNULL_BEGIN

@interface OAOsmBugsRemoteUtil : NSObject <OAOsmBugsUtilsProtocol, NSURLSessionDelegate>

-(OAOsmBugResult *)commit:(OAOsmNotePoint *) point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL) anonymous;
-(OAOsmBugResult *)validateLoginDetails;

@end

NS_ASSUME_NONNULL_END
