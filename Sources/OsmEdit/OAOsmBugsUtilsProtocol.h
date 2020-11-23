//
//  OAOsmBugsUtilsProtocol.h
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
#import "OAOsmPoint.h"

@class OAOsmBugResult;
@class OAOsmNotesPoint;

@protocol OAOsmBugsUtilsProtocol <NSObject>

@required
-(OAOsmBugResult *)commit:(OAOsmNotesPoint *)point text:(NSString *)text action:(EOAAction)action;
-(OAOsmBugResult *)modify:(OAOsmNotesPoint *)point text:(NSString *)text;

@end
