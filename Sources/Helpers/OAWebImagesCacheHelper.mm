//
//  OAWebImagesCacheHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 27/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWebImagesCacheHelper.h"
#import "OADownloadMode.h"
#import "OsmAndApp.h"
#import "OALog.h"

#import <sqlite3.h>
#import "OsmAnd_Maps-Swift.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

// WKWebView has troubles with access for local file storage. So it can't read cached image files directly.
// But we can use workaround. Load cached image in code. Transform it's data to base64 string. Inject this string to html like this:
// <img src=BASE64_STRING>

@implementation OAWebImagesCacheHelper
{
    sqlite3 *_database;
    dispatch_queue_t _dbQueue;
    NSString *_dbFilePath;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _dbQueue = dispatch_queue_create("imageCache_dbQueue", DISPATCH_QUEUE_SERIAL);
        
        _dbFilePath = OsmAndApp.instance.documentsPath;
        if ([self getDbFoldername])
        {
            _dbFilePath = [_dbFilePath stringByAppendingPathComponent:[self getDbFoldername]];
            BOOL isDir = YES;
            if (![[NSFileManager defaultManager] fileExistsAtPath:_dbFilePath isDirectory:&isDir])
                [[NSFileManager defaultManager] createDirectoryAtPath:_dbFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _dbFilePath = [_dbFilePath stringByAppendingPathComponent:[self getDbFilename]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:_dbFilePath] == NO)
        {
            [self createDB];
        }
    }
    return self;
}

// Overriding in sublcass
- (NSString *) getDbFilename
{
    return nil;
}

// Overriding in sublcass
- (NSString *) getDbFoldername
{
    return nil;
}


- (void) processWholeHTML:(NSString *)html downloadMode:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow onComplete:(void (^)(NSString *htmlWithImages))onComplete
{
    NSArray<NSString *> *imageLinks = [self extractImagesLinksFromHtml:html];
    if (imageLinks.count > 0)
    {
        __block NSInteger downloadsCount = imageLinks.count;
    
        for (NSString *link in imageLinks)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                
                [self fetchSingleImageByURL:link customKey:nil downloadMode:downloadMode onlyNow:onlyNow onComplete:^(NSString *imageData) {
                    
                    downloadsCount -= 1;
                    if (downloadsCount == 0)
                    {
                        NSString *htmlWithImages = [self injectBase64ImageDataToHtml:html imageLinks:imageLinks];
                        onComplete(htmlWithImages);
                    }
                    
                }];
            
            });
        }
    }
    else
    {
        onComplete(nil);
    }
}


- (void) fetchSingleImageByURL:(NSString *)url customKey:(NSString *)customKey downloadMode:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow onComplete:(void (^)(NSString *imageData))onComplete
{
    NSString *key = customKey ? customKey : [self getDbKeyByLink:url];
    NSString *savedImageAsBase64 = [self readImageByDbKey:key];
    if (savedImageAsBase64)
    {
        onComplete(savedImageAsBase64);
    }
    else
    {
        if ([self isDownloadingAllowedFor:downloadMode onlyNow:onlyNow])
        {
            [self downloadImage:url customKey:key onComplete:^(NSString *imageData) {
                onComplete(imageData);
            }];
        }
        else
        {
            onComplete(@"");
        }
    }
}


//MARK: Html

- (NSArray<NSString *> *) extractImagesLinksFromHtml:(NSString *)html
{
    NSMutableArray<NSString *> *allImageLinks = [NSMutableArray array];
    NSInteger currentIndex = 0;
    NSRange nextImgTagRange = [html rangeOfString:@"<img" options:0 range:NSMakeRange(currentIndex, [html length])];
    
    while (nextImgTagRange.location != NSNotFound)
    {
        currentIndex = nextImgTagRange.location + nextImgTagRange.length;
        NSRange srcStartTagRange = [html rangeOfString:@"src=\"" options:0 range:NSMakeRange(currentIndex, [html length] - currentIndex)];
        
        currentIndex = srcStartTagRange.location + srcStartTagRange.length;
        NSRange srcEndTagRange = [html rangeOfString:@"\"" options:0 range:NSMakeRange(currentIndex, [html length] - currentIndex)];
        
        NSString *imageLink = [html substringWithRange:NSMakeRange(currentIndex, srcEndTagRange.location - srcStartTagRange.location - srcStartTagRange.length)];
        [allImageLinks addObject:imageLink];
        
        currentIndex = srcEndTagRange.location + srcEndTagRange.length;
        nextImgTagRange = [html rangeOfString:@"<img" options:0 range:NSMakeRange(currentIndex, [html length] - currentIndex)];
    }

    return allImageLinks;
}

- (NSString *) injectBase64ImageDataToHtml:(NSString *)html imageLinks:(NSArray<NSString *> *)imageLinks
{
    NSString *resultHtml = html;
    for (NSString *link in imageLinks)
    {
        NSString *key = [self getDbKeyByLink:link];
        NSString *imageAsBase64String = [self readImageByDbKey:key];
        if (!imageAsBase64String && imageAsBase64String.length == 0 )
            imageAsBase64String = @"";
        
        NSString *srcTagContent = [OAImageToStringConverter getHtmlImgSrcTagContent:imageAsBase64String];
        resultHtml = [resultHtml stringByReplacingOccurrencesOfString:link withString:srcTagContent];
    }
    return resultHtml;
}


//MARK: Network

- (BOOL) isDownloadingAllowedFor:(OADownloadMode *)downloadMode onlyNow:(BOOL)onlyNow
{
    if ( (onlyNow && [AFNetworkReachabilityManager sharedManager].isReachable) ||
         (downloadMode.isDownloadViaAnyNetwork && [AFNetworkReachabilityManager sharedManager].isReachable) ||
         (downloadMode.isDownloadOnlyViaWifi && [AFNetworkReachabilityManager sharedManager].isReachableViaWiFi) )
    {
        return YES;
    }
    return NO;
}

- (void) downloadImage:(NSString *)url customKey:(NSString *)customKey onComplete:(void (^)(NSString *imageData))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:url]];
        if (imageData)
        {
            NSString *base64String = [OAImageToStringConverter imageDataToBase64String:imageData];
            if (base64String)
            {
                NSString *dbKey = customKey ? customKey : [self getDbKeyByLink:url];
                [self saveImage:base64String dbKey:dbKey];
                
                if (onComplete)
                    onComplete(base64String);
            }
        }
        else
        {
            if (onComplete)
                onComplete(nil);
        }
    });
}


//MARK: Database

- (NSString *) getDbKeyByLink:(NSString *)url
{
    return url;
}

- (void) createDB
{
    dispatch_sync(_dbQueue, ^{
        const char *dbpath = [_dbFilePath UTF8String];
        if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
        {
            char *errMsg;
            if (sqlite3_exec(_database, [@"CREATE TABLE IF NOT EXISTS images (key TEXT, image_base64_data TEXT, timestamp INTEGER);" UTF8String], NULL, NULL, &errMsg) != SQLITE_OK)
            {
                OALog(@"Failed to create table: %@", [NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding]);
            }
            if (errMsg != NULL) sqlite3_free(errMsg);
            sqlite3_close(_database);
        }
    });
}

- (NSString *) readImageByDbKey:(NSString *)key
{
    __block NSString *result = nil;
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [@"SELECT image_base64_data FROM images WHERE key = ?" UTF8String];
            if (sqlite3_prepare_v2(_database, stmt, -1, &statement, NULL) == SQLITE_OK)
            {
                sqlite3_bind_text(statement, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
                while (sqlite3_step(statement) == SQLITE_ROW)
                {
                    result = [[NSString alloc] initWithUTF8String:(const char *) sqlite3_column_text(statement, 0)];
                    break;
                }
                sqlite3_finalize(statement);
            }
            sqlite3_close(_database);
        }
    });
    return result;
}

- (void) saveImage:(NSString *)imageAsBase64 dbKey:(NSString *)key
{
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [@"INSERT INTO images (key, image_base64_data, timestamp) VALUES (?, ?, ?)" UTF8String];
            sqlite3_prepare_v2(_database, stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [key UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(statement, 2, [imageAsBase64 UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(statement, 3, ((int)[NSDate now].timeIntervalSince1970));
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        }
    });
}

- (void) updateImage:(NSString *)imageAsBase64 dbKey:(NSString *)key
{
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [@"UPDATE images SET image_base64_data = ?, timestamp = ? WHERE key = ?" UTF8String];
            sqlite3_prepare_v2(_database, stmt, -1, &statement, NULL);
            sqlite3_bind_text(statement, 1, [imageAsBase64 UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int64(statement, 2, ((int)[NSDate now].timeIntervalSince1970));
            sqlite3_bind_text(statement, 3, [key UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        }
    });
}

- (void) cleanAllData
{
    const char *dbpath = [_dbFilePath UTF8String];
    dispatch_sync(_dbQueue, ^{
        if (sqlite3_open(dbpath, &_database) == SQLITE_OK)
        {
            sqlite3_stmt *statement;
            const char *stmt = [@"DELETE FROM images" UTF8String];
            sqlite3_prepare_v2(_database, stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            
            stmt = [@"VACUUM" UTF8String];
            sqlite3_prepare_v2(_database, stmt, -1, &statement, NULL);
            sqlite3_step(statement);
            sqlite3_finalize(statement);
            sqlite3_close(_database);
        }
    });
}

- (double) getFileSize
{
    return (double)[[[NSFileManager defaultManager] attributesOfItemAtPath:_dbFilePath error:nil] fileSize];
}

- (NSString *) getFormattedFileSize
{
    return [NSByteCountFormatter stringFromByteCount:[self getFileSize] countStyle:NSByteCountFormatterCountStyleFile];
}

@end
