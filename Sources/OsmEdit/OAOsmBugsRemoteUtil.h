//
//  OAOsmBugsRemoteUtil.h
//  OsmAnd
//
//  Created by Paul on 2/9/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAOsmBugsUtilsProtocol.h"

@class OAOsmNotePoint;
@class OAOsmBugResult;
NS_ASSUME_NONNULL_BEGIN

@interface OAOsmBugsRemoteUtil : NSObject <OAOsmBugsUtilsProtocol>

-(OAOsmBugResult *)commit:(OAOsmNotePoint *) point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL) anonymous;
-(OAOsmBugResult *)validateLoginDetails;

@end

NS_ASSUME_NONNULL_END
