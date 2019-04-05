//
//  OAOsmBugsRemoteUtil.h
//  OsmAnd
//
//  Created by Paul on 2/9/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/osmedit/OsmBugsRemoteUtil.java
//  git revision 146449a936925552950be737b9645f9b9a043477

#import <Foundation/Foundation.h>
#import "OAOsmBugsUtilsProtocol.h"

@class OAOsmNotePoint;
@class OAOsmBugResult;
NS_ASSUME_NONNULL_BEGIN

@interface OAOsmBugsRemoteUtil : NSObject <OAOsmBugsUtilsProtocol, NSURLSessionDelegate>

-(OAOsmBugResult *)commit:(OAOsmNotePoint *) point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL) anonymous;
-(OAOsmBugResult *)validateLoginDetails;

@end

NS_ASSUME_NONNULL_END
