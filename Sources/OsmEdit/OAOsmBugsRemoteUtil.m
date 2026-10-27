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
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const GET = @"GET";
static NSString * const POST = @"POST";

static NSString * const NOTES_API_BASE_URL = @"https://api.openstreetmap.org/api/0.6/notes";
static NSString * const USERS_API_BASE_URL = @"https://api.openstreetmap.org/api/0.6/user/details";

@interface OAOsmBugsRemoteUtil () <NSXMLParserDelegate>

@end

@implementation OAOsmBugsRemoteUtil
{
    NSString *_displayName;
    NSNumber *_userID;
    NSNumber *_noteID;
    NSMutableString *_noteIDText;
    NSArray *_notes;
    NSError *_requestError;
    NSInteger _statusCode;
    NSMapTable<OAOsmNotePoint *, NSDictionary *> *_uploadAttempts;
}

- (OAOsmBugResult *)commit:(OAOsmNotePoint *)point text:(NSString *)text action:(EOAAction)action {
    return [self commit:point text:text action:action anonymous:NO];
}

- (OAOsmBugResult *)modify:(OAOsmNotePoint *)point text:(NSString *)text {
    return nil;
}

- (OAOsmBugResult *)commit:(OAOsmNotePoint *)point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL)anonymous
{
    return [self commit:point text:text action:action anonymous:anonymous allowUnconfirmedRetry:NO];
}

- (OAOsmBugResult *)commit:(OAOsmNotePoint *)point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL)anonymous allowUnconfirmedRetry:(BOOL)allowUnconfirmedRetry
{
    @synchronized (self)
    {
        OAOsmBugResult *result = [self commitPoint:point text:text action:action anonymous:anonymous allowUnconfirmedRetry:allowUnconfirmedRetry];
        NSDictionary *attempt = [_uploadAttempts objectForKey:point];
        result.requiresUploadConfirmation = action == CREATE && result.warning && attempt && ![attempt[@"confirmed"] boolValue];
        return result;
    }
}

- (OAOsmBugResult *)commitPoint:(OAOsmNotePoint *)point text:(NSString *)text action:(EOAAction)action anonymous:(BOOL)anonymous allowUnconfirmedRetry:(BOOL)allowUnconfirmedRetry
{
    NSString *result = @"";
    NSString *msg = @"";
    if (action == CREATE)
    {
        NSMutableCharacterSet *allowed = [NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];
        [allowed removeCharactersInString:@"&=+#"];
        result = [NSString stringWithFormat:@"%@?lat=%f&lon=%f&text=%@", NOTES_API_BASE_URL, [point getLatitude], [point getLongitude], [text stringByAddingPercentEncodingWithAllowedCharacters:allowed]];
        msg = @"creating bug";

    }
    else
    {
        NSString *actionString = action == REOPEN ? @"reopen" : (action == MODIFY ? @"comment" : @"close");
        msg = action == REOPEN ? @"reopen note" : (action == MODIFY ? @"adding comment" : @"close note");
        result = [NSString stringWithFormat:@"%@/%lld/%@?text=%@", NOTES_API_BASE_URL, [point getId], actionString, [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    }
    if (!anonymous) {
        OAOsmBugResult *loginResult = [self validateLoginDetails];
        if (loginResult.warning)
            return loginResult;
    }
    if (action == CREATE)
        return [self createNote:point text:text url:result anonymous:anonymous allowUnconfirmedRetry:allowUnconfirmedRetry];
    return [self editingPOI:result requestMethod:POST userOperation:msg anonymous:anonymous];
}

- (OAOsmBugResult *)validateLoginDetails
{
    @synchronized (self)
    {
        _userID = nil;
        return [self editingPOI:[NSString stringWithFormat:@"%@", USERS_API_BASE_URL] requestMethod:GET userOperation:@"validate_login" anonymous:NO];
    }
}

- (OAOsmBugResult *)editingPOI:(NSString *)url requestMethod:(NSString *)requestMethod userOperation:(NSString *)userOperation anonymous:(BOOL)anonymous
{
    NSLog(@"Sending request: %@", url);
    NSURL *urlObj = [[NSURL alloc] initWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    [request setHTTPMethod:requestMethod];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];

    if (!anonymous)
    {
        [request setValue:[OAOsmOAuthHelper getAutorizationHeader] forHTTPHeaderField:@"Authorization"];
    }

    __block OAOsmBugResult *res = [[OAOsmBugResult alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        _requestError = error;
        _statusCode = httpResponse.statusCode;
        _noteID = nil;
        _noteIDText = nil;
        _notes = nil;
        if (error || httpResponse.statusCode < 200 || httpResponse.statusCode >= 300)
        {
            res.warning = data.length > 0 ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
            if (res.warning.length == 0)
                res.warning = error.localizedDescription ?: OALocalizedString(@"osm_upload_failed_descr");
        }
        else if ([urlObj.path hasSuffix:@".json"])
        {
            id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            id features = [json isKindOfClass:NSDictionary.class] ? json[@"features"] : nil;
            if ([features isKindOfClass:NSArray.class] && ((NSArray *)features).count < 10000)
                _notes = features;
            else
                res.warning = OALocalizedString(@"osm_upload_failed_descr");
        }
        else
        {
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
            parser.delegate = self;
            if (![parser parse])
                res.warning = OALocalizedString(@"osm_upload_failed_descr");
            res.userName = _displayName;
            _displayName = nil;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return res;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"user"])
    {
        _displayName = attributeDict[@"display_name"];
        _userID = @([attributeDict[@"id"] longLongValue]);
    }
    else if ([elementName isEqualToString:@"id"])
        _noteIDText = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [_noteIDText appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"id"])
    {
        _noteID = @(_noteIDText.longLongValue);
        _noteIDText = nil;
    }
}

- (NSNumber *)matchingNoteInFeatures:(NSArray *)features attempt:(NSDictionary *)attempt
{
    NSNumber *userID = attempt[@"user_id"];
    if (![userID isKindOfClass:NSNumber.class] || userID.longLongValue <= 0)
        return nil;
    NSDictionary *payload = attempt[@"payload"];
    NSSet *previousIDs = [NSSet setWithArray:attempt[@"previous_ids"]];
    NSNumber *matchedID = nil;
    for (NSDictionary *feature in features)
    {
        NSDictionary *properties = feature[@"properties"];
        NSNumber *noteID = properties[@"id"];
        if ([previousIDs containsObject:noteID])
            continue;
        NSDictionary *geometry = feature[@"geometry"];
        if (![geometry isKindOfClass:NSDictionary.class])
            continue;
        NSArray *coordinates = geometry[@"coordinates"];
        NSArray *comments = properties[@"comments"];
        if (![coordinates isKindOfClass:NSArray.class] || coordinates.count != 2
            || ![coordinates[0] isKindOfClass:NSNumber.class] || ![coordinates[1] isKindOfClass:NSNumber.class]
            || ![comments isKindOfClass:NSArray.class] || comments.count == 0 || ![comments[0] isKindOfClass:NSDictionary.class])
            continue;
        NSDictionary *comment = comments[0];
        if (![comment[@"action"] isEqual:@"opened"] || ![comment[@"uid"] isEqual:userID]
            || ![comment[@"text"] isEqual:payload[@"text"]]
            || fabs([coordinates[0] doubleValue] - [payload[@"lon"] doubleValue]) > 0.0000001
            || fabs([coordinates[1] doubleValue] - [payload[@"lat"] doubleValue]) > 0.0000001)
            continue;
        if (matchedID)
            return nil;
        matchedID = noteID;
    }
    return matchedID;
}

- (OAOsmBugResult *)createNote:(OAOsmNotePoint *)point text:(NSString *)text url:(NSString *)url anonymous:(BOOL)anonymous allowUnconfirmedRetry:(BOOL)allowUnconfirmedRetry
{
    OAOsmBugResult *result = [[OAOsmBugResult alloc] init];
    NSDictionary *payload = @{@"lat": [NSString stringWithFormat:@"%.6f", point.getLatitude],
                              @"lon": [NSString stringWithFormat:@"%.6f", point.getLongitude], @"text": text};
    NSNumber *userID = anonymous ? @0 : _userID;
    if (!_uploadAttempts)
        _uploadAttempts = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsStrongMemory];
    NSDictionary *attempt = [_uploadAttempts objectForKey:point];
    if (attempt && (![attempt[@"payload"] isEqual:payload] || ![attempt[@"user_id"] isEqual:userID]))
    {
        result.warning = OALocalizedString(@"osm_upload_failed_descr");
        return result;
    }
    if ([attempt[@"confirmed"] boolValue])
        return result;
    double latitude = [payload[@"lat"] doubleValue];
    double longitude = [payload[@"lon"] doubleValue];
    NSString *query = [NSString stringWithFormat:@"%@.json?bbox=%.7f,%.7f,%.7f,%.7f&closed=-1&limit=10000", NOTES_API_BASE_URL,
                      MAX(-180, longitude - 0.00001), MAX(-90, latitude - 0.00001), MIN(180, longitude + 0.00001), MIN(90, latitude + 0.00001)];
    result = [self editingPOI:query requestMethod:GET userOperation:@"check notes" anonymous:YES];
    if (result.warning)
        return result;
    NSMutableArray *previousIDs = [NSMutableArray array];
    for (id feature in _notes)
    {
        if (![feature isKindOfClass:NSDictionary.class] || ![feature[@"properties"] isKindOfClass:NSDictionary.class]
            || ![feature[@"properties"][@"id"] isKindOfClass:NSNumber.class])
        {
            result.warning = OALocalizedString(@"osm_upload_failed_descr");
            return result;
        }
        [previousIDs addObject:feature[@"properties"][@"id"]];
    }
    if (attempt)
    {
        if ([self matchingNoteInFeatures:_notes attempt:attempt])
        {
            NSMutableDictionary *confirmed = [attempt mutableCopy];
            confirmed[@"confirmed"] = @YES;
            [_uploadAttempts setObject:confirmed forKey:point];
            return result;
        }
        if (!allowUnconfirmedRetry)
        {
            result.warning = OALocalizedString(@"osm_upload_failed_descr");
            return result;
        }
    }
    [_uploadAttempts setObject:@{@"payload": payload, @"user_id": userID ?: @0, @"previous_ids": previousIDs} forKey:point];
    result = [self editingPOI:url requestMethod:POST userOperation:@"creating bug" anonymous:anonymous];
    if (!result.warning && _noteID.longLongValue <= 0)
        result.warning = OALocalizedString(@"osm_upload_failed_descr");
    BOOL notSent = [_requestError.domain isEqual:NSURLErrorDomain]
        && (_requestError.code == NSURLErrorNotConnectedToInternet || _requestError.code == NSURLErrorCannotFindHost
            || _requestError.code == NSURLErrorCannotConnectToHost);
    if (!result.warning)
    {
        NSMutableDictionary *confirmed = [[_uploadAttempts objectForKey:point] mutableCopy];
        confirmed[@"confirmed"] = @YES;
        [_uploadAttempts setObject:confirmed forKey:point];
    }
    if (notSent || (!_requestError && _statusCode >= 400 && _statusCode < 500 && _statusCode != 408))
        [_uploadAttempts removeObjectForKey:point];
    return result;
}

@end
