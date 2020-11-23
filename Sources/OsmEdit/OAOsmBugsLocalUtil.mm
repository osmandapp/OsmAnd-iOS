//
//  OAOsmBugsLocalUtil.m
//  OsmAnd
//
//  Created by Paul on 1/30/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmBugsLocalUtil.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugResult.h"
#import "OAOsmNotesPoint.h"
#import "OsmAndApp.h"

@implementation OAOsmBugsLocalUtil

- (OAOsmBugResult *)commit:(OAOsmNotesPoint *)point text:(NSString *)text action:(EOAAction)action
{
    OAOsmBugsDBHelper *bugsDb = [OAOsmBugsDBHelper sharedDatabase];
    if(action == CREATE)
    {
        [point setId:MIN(-2, [bugsDb getMinID] - 1)];
        [point setText:text];
        [point setAction:action];
    }
    else
    {
        OAOsmNotesPoint *pnt = [[OAOsmNotesPoint alloc] init];
        [pnt setId:[point getId]];
        [pnt setLatitude:[point getLatitude]];
        [pnt setLongitude:[point getLongitude]];
        [pnt setAction:[point getAction]];
        [pnt setText:[point getText]];
        point = pnt;
    }
    [bugsDb addOsmbugs:point];
    [[OsmAndApp instance].osmEditsChangeObservable notifyEvent];
    return [self wrap:point success:/*db.addOsmbugs(point)*/YES];
}

- (OAOsmBugResult *)modify:(OAOsmNotesPoint *)point text:(NSString *)text
{
    OAOsmNotesPoint *pnt = [[OAOsmNotesPoint alloc] init];
    [pnt setId:[point getId]];
    [pnt setLatitude:[point getLatitude]];
    [pnt setLongitude:[point getLongitude]];
    [pnt setAction:[point getAction]];
    [pnt setText:[point getText]];
    point = pnt;
    [[OAOsmBugsDBHelper sharedDatabase] updateOsmBug:[point getId] text:text];
    return [self wrap:point success:/*db.updateOsmBug(point.getId(), text*/YES];
}

-(OAOsmBugResult *)wrap:(OAOsmNotesPoint *) point success:(BOOL)success
{
    OAOsmBugResult *s = [[OAOsmBugResult alloc] init];
    s.localPoint = point;
    s.warning = success ? nil : @"";
    return s;
}

@end
