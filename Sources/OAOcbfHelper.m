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

+ (void) downloadOcbfIfUpdated
{
    NSString *urlString = @"http://download.osmand.net/regions_v2.ocbf";
    
    OALog(@"Downloading HTTP header from: %@", urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *cachedPathBundle = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"ocbf"];
    NSString *cachedPathLib = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources/regions.ocbf"];

    if (![fileManager fileExistsAtPath:cachedPathLib])
    {
        NSError *error = nil;
        [fileManager copyItemAtPath:cachedPathBundle toPath:cachedPathLib error:&error];
        if (error)
            NSLog(@"Error copying file: %@ to %@ - %@", cachedPathBundle, cachedPathLib, [error localizedDescription]);
    }
    
    BOOL downloadFromServer = NO;
    NSString *lastModifiedString = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse *response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error: NULL];
    if ([response respondsToSelector:@selector(allHeaderFields)])
        lastModifiedString = [[response allHeaderFields] objectForKey:@"Last-Modified"];
    
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
    if ([fileManager fileExistsAtPath:cachedPathLib])
    {
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:cachedPathLib error:&error];
        if (error)
            NSLog(@"Error reading file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);

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
                    NSLog(@"Error setting file attributes for: %@ - %@", cachedPathLib, [error localizedDescription]);
            }
        }
    }  
}

+ (BOOL) isBundledOcbfNewer
{
    NSString *cachedPathBundle = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"ocbf"];
    NSString *cachedPathLib = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources/regions.ocbf"];
    
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

        OALog(@"lastModifiedBundle : %@", lastModifiedBundle);
        OALog(@"lastModifiedLocal : %@", lastModifiedLocal);
        
        return [lastModifiedBundle timeIntervalSince1970] > [lastModifiedLocal timeIntervalSince1970];
    }
}

@end
