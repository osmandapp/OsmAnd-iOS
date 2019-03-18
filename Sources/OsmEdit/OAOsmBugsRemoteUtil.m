//
//  OAOsmBugsRemoteUtil.m
//  OsmAnd
//
//  Created by Paul on 2/9/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOsmBugResult.h"
#import "OAAppSettings.h"

#define GET @"GET"
#define POST @"POST"

static const NSString* NOTES_API_BASE_URL = @"http://api.openstreetmap.org/api/0.6/notes";
static const NSString* USERS_API_BASE_URL = @"https://api.openstreetmap.org/api/0.6/user/details";


@implementation OAOsmBugsRemoteUtil

- (OAOsmBugResult *)commit:(OAOsmNotePoint *)point text:(NSString *)text action:(EOAAction)action {
    return [self commit:point text:text action:action anonymous:NO];
}

- (OAOsmBugResult *)modify:(OAOsmNotePoint *)point text:(NSString *)text {
    return nil;
}

-(OAOsmBugResult *)commit:(OAOsmNotePoint *) point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL) anonymous
{
    NSString *result = @"";
    NSString *msg = @"";
    if (action == CREATE)
    {
        result = [NSString stringWithFormat:@"%@?lat=%f&lon=%f&text=%@", NOTES_API_BASE_URL, [point getLatitude], [point getLongitude], [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
        msg = @"creating bug";
        
    }
    else
    {
        NSString *actionString = action == REOPEN ? @"reopen" : (action == MODIFY ? @"comment" : @"close");
        msg = action == REOPEN ? @"reopen note" : (action == MODIFY ? @"adding comment" : @"close note");
        result = [NSString stringWithFormat:@"%@/%ld/%@?text=%@", NOTES_API_BASE_URL, [point getId], actionString, [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    }
    
    if (!anonymous) {
        OAOsmBugResult *loginResult = [self validateLoginDetails];
        if (loginResult.warning) {
            return loginResult;
        }
    }
    return [self editingPOI:result requestMethod:POST userOperation:msg anonymous:anonymous];
}

-(OAOsmBugResult *)validateLoginDetails
{
    return [self editingPOI:[NSString stringWithFormat:@"%@", USERS_API_BASE_URL] requestMethod:GET userOperation:@"validate_login" anonymous:NO];
}

-(OAOsmBugResult *) editingPOI:(NSString *)url requestMethod:(NSString *)requestMethod userOperation:(NSString *)userOperation anonymous:(BOOL) anonymous
{
    OAOsmBugResult *res = [[OAOsmBugResult alloc] init];
    NSLog(@"Sending request: %@", url);
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    [request setHTTPMethod:requestMethod];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    if (!anonymous)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        NSString *token = [NSString stringWithFormat:@"%@:%@", [settings.osmUserName escapeUrl], [settings.osmUserPassword escapeUrl]];
        [request addValue:[NSString stringWithFormat:@"Basic %@", [[token dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0]] forHTTPHeaderField:@"Authorization"];
    }
    
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    
    if ([urlResponse statusCode] < 200 || [urlResponse statusCode] >= 300)
        res.warning = result;
    
    return res;
}

@end
