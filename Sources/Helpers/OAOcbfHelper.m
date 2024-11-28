//
//  OAOcbfHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 24/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAOcbfHelper.h"
#import "OALog.h"

@implementation OAOcbfHelper

+ (void) downloadOcbfIfUpdated:(void (^)(void))completionHandler
{
    NSString *urlString = @"https://creator.osmand.net/basemap/regions.ocbf";
    
    OALog(@"Downloading HTTP header from: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cachedPathBundle = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"ocbf"];
    NSString *cachedPathLib = [NSHomeDirectory() stringByAppendingString:@"/Documents/Resources/regions.ocbf"];
    
    if (![fileManager fileExistsAtPath:cachedPathLib])
    {
        NSError *error = nil;
        [fileManager copyItemAtPath:cachedPathBundle toPath:cachedPathLib error:&error];
        if (error)
            OALog(@"Error copying file: %@ to %@ - %@", cachedPathBundle, cachedPathLib, [error localizedDescription]);
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        NSInteger responseCode = httpResponse.statusCode;
        if (!error && (responseCode >= 200 && responseCode < 300))
        {
            [self downloadOcbfIfUpdated:url
                     lastModifiedString:httpResponse.allHeaderFields[@"Last-Modified"]
                          cachedPathLib:cachedPathLib];
        }
        if (completionHandler)
            completionHandler();
    }] resume];
}

+ (void)downloadOcbfIfUpdated:(NSURL *)url
           lastModifiedString:(NSString *)lastModifiedString
                cachedPathLib:(NSString *)cachedPathLib
{
    BOOL downloadFromServer = NO;
    NSDate *lastModifiedServer = nil;
    @try
    {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        lastModifiedServer = [df dateFromString:lastModifiedString];
    }
    @catch (NSException * e)
    {
        OALog(@"Error parsing last modified date: %@ - %@", lastModifiedString, [e description]);
    }
    OALog(@"lastModifiedServer: %@", lastModifiedServer);
    
    NSDate *lastModifiedLocal = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachedPathLib])
    {
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:cachedPathLib error:&error];
        if (error)
            OALog(@"Error reading file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);

        lastModifiedLocal = [fileAttributes fileModificationDate];
        OALog(@"lastModifiedLocal : %@", lastModifiedLocal);
    }
    
    // Download file from server if we don't have a local file
    if (!lastModifiedLocal)
        downloadFromServer = YES;

    // Download file from server if the server modified timestamp is later than the local modified timestamp
    if ([lastModifiedLocal laterDate:lastModifiedServer] == lastModifiedServer)
        downloadFromServer = YES;
    
    if (downloadFromServer)
    {
        OALog(@"Downloading new file from server");
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data)
        {
            // Save the data
            if ([data writeToFile:cachedPathLib atomically:YES])
                OALog(@"Downloaded file saved to: %@", cachedPathLib);
            
            // Set the file modification date to the timestamp from the server
            if (lastModifiedServer)
            {
                NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:lastModifiedServer forKey:NSFileModificationDate];
                NSError *error = nil;
                if ([fileManager setAttributes:fileAttributes ofItemAtPath:cachedPathLib error:&error])
                    OALog(@"File modification date updated");

                if (error)
                    OALog(@"Error setting file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);
            }
        }
    }  
}

+ (BOOL) isBundledOcbfNewer
{
    NSString *cachedPathBundle = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"ocbf"];
    NSString *cachedPathLib = [NSHomeDirectory() stringByAppendingString:@"/Documents/Resources/regions.ocbf"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:cachedPathLib])
    {
        return NO;
    }
    else
    {
        NSDate *lastModifiedBundle = nil;
        NSDate *lastModifiedLocal = nil;

        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:cachedPathBundle error:&error];
        if (error)
            OALog(@"Error reading file attributes for: %@ - %@", cachedPathBundle, [error localizedDescription]);
        
        lastModifiedBundle = [fileAttributes fileModificationDate];

        fileAttributes = [fileManager attributesOfItemAtPath:cachedPathLib error:&error];
        if (error)
            OALog(@"Error reading file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);
        
        lastModifiedLocal = [fileAttributes fileModificationDate];

        OALog(@"lastModifiedBundle : %@", lastModifiedBundle);
        OALog(@"lastModifiedLocal : %@", lastModifiedLocal);
        
        return [lastModifiedBundle timeIntervalSince1970] > [lastModifiedLocal timeIntervalSince1970];
    }
}

@end
