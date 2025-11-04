//
//  OAOcbfHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 24/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAOcbfHelper.h"

@implementation OAOcbfHelper

+ (void)downloadOcbfIfUpdated:(void (^)(void))completionHandler
{
    NSString *urlString = @"https://builder.osmand.net/basemap/regions.ocbf";
    NSLog(@"[OCBF] Starting check for update at URL: %@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url)
    {
        NSLog(@"[OCBF] Invalid URL: %@", urlString);
        if (completionHandler)
            completionHandler();
        return;
    }

    NSLog(@"[OCBF] Skip downloading URL: %@", urlString);
    if (completionHandler)
        completionHandler();
    return;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *cachedPathBundle = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"ocbf"];
    NSString *cachedPathLib = [NSHomeDirectory() stringByAppendingString:@"/Documents/Resources/regions.ocbf"];
    
    NSLog(@"[OCBF] Bundle path: %@", cachedPathBundle);
    NSLog(@"[OCBF] Library path: %@", cachedPathLib);
    
    if (![fileManager fileExistsAtPath:cachedPathLib])
    {
        NSError *copyError = nil;
        [fileManager copyItemAtPath:cachedPathBundle toPath:cachedPathLib error:&copyError];
        if (copyError)
        {
            NSLog(@"[OCBF] Error copying file from %@ to %@ — %@", cachedPathBundle, cachedPathLib, copyError.localizedDescription);
        }
        else
        {
            NSLog(@"[OCBF] Copied default OCBF from bundle to library.");
        }
    }
    else
    {
        NSLog(@"[OCBF] Cached OCBF already exists at %@", cachedPathLib);
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    NSLog(@"[OCBF] Sending HTTP HEAD request to check Last-Modified header...");
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (error)
        {
            NSLog(@"[OCBF] Error during HEAD request: %@", error.localizedDescription);
            if (completionHandler)
                completionHandler();
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger responseCode = httpResponse.statusCode;
        NSLog(@"[OCBF] HTTP response: %ld", (long)responseCode);
        
        if (responseCode >= 200 && responseCode < 300)
        {
            NSString *lastModified = httpResponse.allHeaderFields[@"Last-Modified"];
            NSLog(@"[OCBF] Last-Modified header: %@", lastModified ?: @"<none>");
            
            [self downloadOcbfIfUpdated:url
                     lastModifiedString:lastModified
                          cachedPathLib:cachedPathLib];
        }
        else
        {
            NSLog(@"[OCBF] HEAD request returned non-success code: %ld", (long)responseCode);
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
        NSLog(@"Error parsing last modified date: %@ - %@", lastModifiedString, [e description]);
    }
    NSLog(@"lastModifiedServer: %@", lastModifiedServer);
    
    NSDate *lastModifiedLocal = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:cachedPathLib])
    {
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:cachedPathLib error:&error];
        if (error)
            NSLog(@"Error reading file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);

        lastModifiedLocal = [fileAttributes fileModificationDate];
        NSLog(@"lastModifiedLocal : %@", lastModifiedLocal);
    }
    
    // Download file from server if we don't have a local file
    if (!lastModifiedLocal)
        downloadFromServer = YES;

    // Download file from server if the server modified timestamp is later than the local modified timestamp
    if ([lastModifiedLocal laterDate:lastModifiedServer] == lastModifiedServer)
        downloadFromServer = YES;
    
    if (downloadFromServer)
    {
        NSLog(@"Downloading new file from server");
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data)
        {
            // Save the data
            if ([data writeToFile:cachedPathLib atomically:YES])
                NSLog(@"Downloaded file saved to: %@", cachedPathLib);
            
            // Set the file modification date to the timestamp from the server
            if (lastModifiedServer)
            {
                NSDictionary *fileAttributes = [NSDictionary dictionaryWithObject:lastModifiedServer forKey:NSFileModificationDate];
                NSError *error = nil;
                if ([fileManager setAttributes:fileAttributes ofItemAtPath:cachedPathLib error:&error])
                    NSLog(@"File modification date updated");

                if (error)
                    NSLog(@"Error setting file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);
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
            NSLog(@"Error reading file attributes for: %@ - %@", cachedPathBundle, [error localizedDescription]);
        
        lastModifiedBundle = [fileAttributes fileModificationDate];

        fileAttributes = [fileManager attributesOfItemAtPath:cachedPathLib error:&error];
        if (error)
            NSLog(@"Error reading file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);
        
        lastModifiedLocal = [fileAttributes fileModificationDate];

        NSLog(@"lastModifiedBundle : %@", lastModifiedBundle);
        NSLog(@"lastModifiedLocal : %@", lastModifiedLocal);
        
        return [lastModifiedBundle timeIntervalSince1970] > [lastModifiedLocal timeIntervalSince1970];
    }
}

@end
