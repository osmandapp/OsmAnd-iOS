//
//  OAXmlImportHandler.m
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAXmlImportHandler.h"
#import "OARootViewController.h"
#import "OAIndexConstants.h"
#import "OsmAndApp.h"
#import "OAFileImportHelper.h"
#import "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <qxmlstream.h>

typedef NS_ENUM(NSInteger, EOAXmlFileType) {
    EOAXmlFileTypeUnsupported = -1,
    EOAXmlFileTypeGpx = 0,
    EOAXmlFileTypeKml,
    EOAXmlFileTypeKmz,
    EOAXmlFileTypeRouting,
    EOAXmlFileTypeRendering
};

@implementation OAXmlImportHandler
{
    NSURL *_url;
    EOAXmlFileType _fileType;
}

- (instancetype) initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
        _fileType = [self parseFileType];
    }
    return self;
}

- (void) doImport:(NSString *)path destPath:(NSString *)destPath
{
    BOOL imported = [[OAFileImportHelper sharedInstance] importResourceFileFromPath:path toPath:destPath];
    if (imported)
    {
        if (_fileType == EOAXmlFileTypeRouting)
            [OsmAndApp.instance loadRoutingFiles];
        else if (_fileType == EOAXmlFileTypeRendering)
            OsmAndApp.instance.resourcesManager->rescanUnmanagedStoragePaths();
    }
    NSString *message = imported ? [NSString stringWithFormat:OALocalizedString(@"res_import_success"), destPath.lastPathComponent] : OALocalizedString(@"obf_import_failed");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
}

- (void) handleImport
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = _url.path;
    NSString *newExt = [self fileExtensionByType:_fileType];
    if (newExt.length > 0)
    {
        NSString *newPath = [path.stringByDeletingPathExtension stringByAppendingPathExtension:newExt];
        [fileManager moveItemAtPath:path toPath:newPath error:nil];
        [OARootViewController.instance importAsGPX:[NSURL fileURLWithPath:newPath] showAlerts:YES openGpxView:YES];
        return;
    }
    NSString *destPath = self.getDestinationFilePath;
    if ([path isEqualToString:destPath])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"obf_import_already_exists_short") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        switch (_fileType)
        {
            case EOAXmlFileTypeRendering:
            case EOAXmlFileTypeRouting:
            {
                BOOL fileExists = [fileManager fileExistsAtPath:destPath];
                if (fileExists)
                {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"obf_import_already_exists") preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    }]];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"fav_replace") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self doImport:path destPath:destPath];
                    }]];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"gpx_add_new") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self doImport:path destPath:[self getNewPath:destPath]];
                    }]];
                    
                    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
                }
                else
                {
                    [self doImport:path destPath:destPath];
                }
            }
            default:
            {
                NSLog(@"Could not import: %@", destPath);
            }
        }
    }
}

- (NSString *) getNewPath:(NSString *)destPath
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *destFilePath = destPath;
    NSString *destDir = [destPath stringByDeletingLastPathComponent];
    NSString *destFileName = destPath.lastPathComponent;
    BOOL isRenderingFile = _fileType == EOAXmlFileTypeRendering;
    destFileName = isRenderingFile ? [destFileName stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""] : destFileName;
    while ([fileManager fileExistsAtPath:destFilePath])
    {
        destFileName = [OAUtilities createNewFileName:destFileName];
        if (isRenderingFile)
            destFileName = [destFileName stringByAppendingString:RENDERER_INDEX_EXT];
        destFilePath = [destDir stringByAppendingPathComponent:destFileName];
    }
    return destFilePath;
}

- (NSString *) getDestinationDir
{
    OsmAndAppInstance app = OsmAndApp.instance;
    if (_fileType == EOAXmlFileTypeRouting)
        return [app.documentsPath stringByAppendingPathComponent:@"routing"];
    else if (_fileType == EOAXmlFileTypeRendering)
        return [app.documentsPath stringByAppendingPathComponent:@"rendering"];
    return nil;
}

- (NSString *) getDestinationFilePath
{
    NSString *destDir = [self getDestinationDir];
    if (destDir != nil)
    {
        NSFileManager *fileManager = NSFileManager.defaultManager;
        if (![fileManager fileExistsAtPath:destDir])
            [fileManager createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *destFileName = _url.path.lastPathComponent;
        if (_fileType == EOAXmlFileTypeRendering && ![destFileName hasSuffix:RENDERER_INDEX_EXT])
        {
            NSString *fileName = destFileName.stringByDeletingPathExtension;
            destFileName = [fileName stringByAppendingString:RENDERER_INDEX_EXT];
        }
        return [destDir stringByAppendingPathComponent:destFileName];
    }
    return nil;
}

- (NSString *)fileExtensionByType:(EOAXmlFileType)type
{
    switch (type)
    {
        case EOAXmlFileTypeKml:
            return @"kml";
        case EOAXmlFileTypeGpx:
            return @"gpx";
        default:
            return @"";
    }
}

- (EOAXmlFileType) parseFileType
{
    QFile file(QString::fromNSString(_url.path));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return EOAXmlFileTypeUnsupported;
    
    QXmlStreamReader xmlReader(&file);
    while (!xmlReader.atEnd() && !xmlReader.hasError())
    {
        xmlReader.readNext();
        const auto tagName = xmlReader.name();
        if (xmlReader.isStartElement())
        {
            if (tagName == QStringLiteral("gpx"))
                return EOAXmlFileTypeGpx;
            else if (tagName == QStringLiteral("osmand_routing_config"))
                return EOAXmlFileTypeRouting;
            else if (tagName == QStringLiteral("renderingStyle"))
                return EOAXmlFileTypeRendering;
            else if (tagName == QStringLiteral("kml"))
                return EOAXmlFileTypeKml;
        }
    }
    return EOAXmlFileTypeUnsupported;
}

@end
