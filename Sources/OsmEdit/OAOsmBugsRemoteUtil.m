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

static const NSString* NOTES_API_BASE_URL = @"https://api.openstreetmap.org/api/0.6/notes";
static const NSString* USERS_API_BASE_URL = @"https://api.openstreetmap.org/api/0.6/user/details";


@implementation OAOsmBugsRemoteUtil
{
    BOOL _anonymous;
}

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
        result = [NSString stringWithFormat:@"%@/%lld/%@?text=%@", NOTES_API_BASE_URL, [point getId], actionString, [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    }
    _anonymous = anonymous;
    if (!anonymous) {
        OAOsmBugResult *loginResult = [self validateLoginDetails];
        if (loginResult.warning)
            return loginResult;
    }
    return [self editingPOI:result requestMethod:POST userOperation:msg anonymous:anonymous];
}

-(OAOsmBugResult *)validateLoginDetails
{
    return [self editingPOI:[NSString stringWithFormat:@"%@", USERS_API_BASE_URL] requestMethod:GET userOperation:@"validate_login" anonymous:NO];
}

-(OAOsmBugResult *) editingPOI:(NSString *)url requestMethod:(NSString *)requestMethod userOperation:(NSString *)userOperation anonymous:(BOOL) anonymous
{
    NSLog(@"Sending request: %@", url);
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    [request setHTTPMethod:requestMethod];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    
    if (!_anonymous)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", settings.osmUserName.get, settings.osmUserPassword.get];
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat: @"Basic %@", [authData base64EncodedStringWithOptions:0]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    
    __block OAOsmBugResult *res = [[OAOsmBugResult alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (error || httpResponse.statusCode < 200 || httpResponse.statusCode >= 300)
            res.warning = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return res;
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler {
    if (!_anonymous)
    {
        if (challenge.previousFailureCount > 1)
        {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
        else
        {
            OAAppSettings *settings = [OAAppSettings sharedManager];
            NSURLCredential *credential = [NSURLCredential credentialWithUser:settings.osmUserName.get
                                                                     password:settings.osmUserPassword.get
                                                                  persistence:NSURLCredentialPersistenceForSession];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        }
    }
    else
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
}

@end
