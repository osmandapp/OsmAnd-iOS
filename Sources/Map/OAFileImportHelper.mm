//
//  OAMapImportHelper.m
//  OsmAnd
//
//  Created by Paul on 17/07/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAFileImportHelper.h"
#import "OALog.h"
#import "OsmAndApp.h"

@implementation OAFileImportHelper
{
    NSFileManager *_fileManager;
    
    OsmAndAppInstance _app;
}

+ (OAFileImportHelper *)sharedInstance
{
    static dispatch_once_t once;
    static OAFileImportHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _fileManager = [NSFileManager defaultManager];
        NSArray *paths = [_fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        _documentsDir = documentsURL.path;
    }
    return self;
}

- (BOOL)importObfFileFromPath:(NSString *)filePath newFileName:(NSString *)newFileName
{
    NSString *fileName;
    if (newFileName)
        fileName = newFileName;
    else
        fileName = [filePath lastPathComponent];

    NSString *path = [self.documentsDir stringByAppendingPathComponent:fileName];
    if ([filePath isEqualToString:path])
    {
        [OAUtilities denyAccessToFile:filePath removeFromInbox:NO];
        return YES;
    }

    QString str = QString::fromNSString(fileName);
    QString resourceId = str.toLower().remove(QStringLiteral("_2"));
    if (_app.resourcesManager->isLocalResource(resourceId))
        _app.resourcesManager->uninstallResource(resourceId);
    
    NSError *error;
    [_fileManager copyItemAtPath:filePath toPath:path error:&error];
    if (error)
        OALog(@"Failed to import OBF file: %@", filePath);

    [OAUtilities denyAccessToFile:filePath removeFromInbox:YES];
    
    if (error)
    {
        return NO;
    }
    else
    {
        _app.resourcesManager->rescanUnmanagedStoragePaths();
        [_app.localResourcesChangedObservable notifyEventWithKey:nil];
        return YES;
    }
}

// Used to import routing.xml and .render.xml
- (BOOL)importResourceFileFromPath:(NSString *)filePath toPath:(NSString *)destPath
{
    NSString *destDir = destPath.stringByDeletingLastPathComponent;
    
    if ([_fileManager fileExistsAtPath:destPath])
        [_fileManager removeItemAtPath:destPath error:nil];
    else if (![_fileManager fileExistsAtPath:destDir])
        [_fileManager createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSError *error;
    [_fileManager copyItemAtPath:filePath toPath:destPath error:&error];
    if (error)
        OALog(@"Failed to import resource: %@", filePath);

    [OAUtilities denyAccessToFile:filePath removeFromInbox:YES];
    
    if (error)
    {
        return NO;
    }
    else
    {
        [_app.localResourcesChangedObservable notifyEventWithKey:nil];
        return YES;
    }
}

- (NSString *)getNewNameIfExists:(NSString *)fileName
{
    NSString *res;
    QString resourceId = QString::fromNSString(fileName).toLower().remove(QStringLiteral("_2"));
    if (_app.resourcesManager->isLocalResource(resourceId))
    {
        NSString *ext = [fileName pathExtension];
        NSString *newName;
        for (int i = 2; i < 100000; i++) {
            newName = [[NSString stringWithFormat:@"%@-%d", [fileName stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
            if (![_fileManager fileExistsAtPath:[self.documentsDir stringByAppendingPathComponent:newName]])
                break;
        }
        res = newName;
    }
    return res;
}

@end
