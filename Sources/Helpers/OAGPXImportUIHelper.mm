//
//  OAGPXImportUIHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 27/01/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAGPXImportUIHelper.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAKml2Gpx.h"
#import "OAIndexConstants.h"
#import "Localization.h"
#import "OAGPXAppearanceCollection.h"
#import <MBProgressHUD.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define GPX_EXT @"gpx"
#define KML_EXT @"kml"
#define KMZ_EXT @"kmz"

#define kImportFolderName @"import"

NSNotificationName const OAGPXImportUIHelperDidFinishImportNotification = @"OAGPXImportUIHelperDidFinishImporNotification";

@interface OAGPXImportUIHelper () <UIDocumentPickerDelegate>
@end

@implementation OAGPXImportUIHelper
{
    UIViewController __weak *_hostVC;
    MBProgressHUD *_progressHUD;
    OsmAndAppInstance _app;
    
    NSURL *_importUrl;
    NSString *_importGpxPath;
    OASGpxFile *_doc;
    NSString *_newGpxName;
}

static UIViewController *parentController;

- (instancetype) initWithHostViewController:(UIViewController *)hostVC
{
    self = [super init];
    if (self) 
    {
        _hostVC = hostVC;
        _app = [OsmAndApp instance];
        _importGpxPath = [_app.gpxPath stringByAppendingPathComponent:kImportFolderName];
    }
    return self;
}

- (void) onImportClicked
{
    [self onImportClickedWithDestinationFolderPath:nil];
}

- (void) onImportClickedWithDestinationFolderPath:(NSString *)destPath
{
    _importGpxPath = [_app.gpxPath stringByAppendingPathComponent:destPath ? [self trim:destPath] : kImportFolderName];
    NSArray<UTType *> *contentTypes = @[[UTType importedTypeWithIdentifier:@"com.topografix.gpx" conformingToType:UTTypeXML],
                                        [UTType importedTypeWithIdentifier:@"com.google.earth.kmz" conformingToType:UTTypeXML],
                                        [UTType importedTypeWithIdentifier:@"com.google.earth.kml" conformingToType:UTTypeXML]];
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:YES];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    if (_hostVC)
        [_hostVC presentViewController:documentPickerVC animated:YES completion:nil];
}

- (NSString *)trim:(NSString *)path
{
    if ([path hasPrefix:@"/"])
        return [path substringFromIndex:1];
    return path;
}

- (void)doPush
{
    if (_hostVC)
    {
        parentController = _hostVC.parentViewController;
        
        CATransition* transition = [CATransition animation];
        transition.duration = 0.4;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromRight;
        [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
        [[OARootViewController instance].navigationController popToRootViewControllerAnimated:NO];
    }
}

+ (void)doPop
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromLeft;
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController pushViewController:parentController animated:NO];
    
    parentController = nil;
}

- (void) showProgressHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL wasVisible = NO;
        if (_progressHUD)
        {
            wasVisible = YES;
            [_progressHUD hide:NO];
        }
        UIView *topView = [UIApplication sharedApplication].mainWindow;
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = .5f;
        _progressHUD.removeFromSuperViewOnHide = YES;
        [topView addSubview:_progressHUD];
        
        [_progressHUD show:!wasVisible];
    });
}

- (void) hideProgressHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressHUD)
        {
            [_progressHUD hide:YES];
            _progressHUD = nil;
        }
    });
}

- (void) showImportGpxAlert:(NSString *)title
                    message:(NSString *)message
          cancelButtonTitle:(NSString *)cancelButtonTitle
          otherButtonTitles:(NSArray <NSString *> *)otherButtonTitles
                openGpxView:(BOOL)openGpxView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        id createCopyHandler = ^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSFileManager *fileMan = [NSFileManager defaultManager];
                NSString *ext = [_importUrl.path pathExtension];
                NSString *newName;
                for (int i = 2; i < 100000; i++)
                {
                    newName = [[NSString stringWithFormat:@"%@_%d", [[_importUrl.path lastPathComponent] stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
                    if (![fileMan fileExistsAtPath:[_importGpxPath stringByAppendingPathComponent:newName]])
                        break;
                }
                
                _newGpxName = [newName copy];

                OASGpxDataItem *gpx = [self doImport];
                if (gpx && openGpxView)
                {
                    [self doPush];
                    auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
                    trackItem.dataItem = gpx;
                    [[OARootViewController instance].mapPanel openTargetViewWithGPX:trackItem];
                }
            });
        };
        
        id overwriteHandler = ^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _newGpxName = nil;
                [self removeFromDB];

                OASGpxDataItem *gpx = [self doImport];
                if (openGpxView && gpx)
                {
                    [self doPush];
                    auto trackItem = [[OASTrackItem alloc] initWithFile:gpx.file];
                    trackItem.dataItem = gpx;
                    [[OARootViewController instance].mapPanel openTargetViewWithGPX:trackItem];
                }
            });
        };
        
        for (NSInteger i = 0; i < otherButtonTitles.count; i++)
        {
            [alert addAction:[UIAlertAction actionWithTitle:otherButtonTitles[i] style:UIAlertActionStyleDefault handler:i == 0 ? createCopyHandler : overwriteHandler]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [OAUtilities denyAccessToFile:_importUrl.path removeFromInbox:YES];
        }]];
        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
    });
}

- (void) handleKmzImport
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    OsmAnd::ArchiveReader reader(QString::fromNSString(_importUrl.path));
    NSString *tmpKmzPath = [[OsmAndApp instance].documentsPath stringByAppendingPathComponent:@"kmzTemp"];
    BOOL success = reader.extractAllItemsTo(QString::fromNSString(tmpKmzPath));
    if (success)
    {
        for (NSString *filename in [fileManager contentsOfDirectoryAtPath:tmpKmzPath error:nil])
        {
            if ([filename.pathExtension isEqualToString:@"kml"])
            {
                [self handleKmlImport:[NSData dataWithContentsOfFile:[tmpKmzPath stringByAppendingPathComponent:filename]]];
                break;
            }
        }
    }
    else
    {
        [OAUtilities denyAccessToFile:_importUrl.path removeFromInbox:YES];
        _importUrl = nil;
    }
    [fileManager removeItemAtPath:tmpKmzPath error:nil];
}

- (void) handleKmlImport:(NSData *)data
{
    if (data && data.length > 0)
    {
        NSString *gpxStr = [OAKml2Gpx toGpx:data];
        if (gpxStr)
        {
            NSString *finalFilePath = [[[_app.gpxPath stringByAppendingPathComponent:TEMP_DIR]
                                        stringByAppendingPathComponent:[_importUrl.lastPathComponent stringByDeletingPathExtension]] stringByAppendingPathExtension:GPX_EXT];
            NSError *err;
            if (![NSFileManager.defaultManager fileExistsAtPath:[_app.gpxPath stringByAppendingPathComponent:TEMP_DIR]])
            {
                [NSFileManager.defaultManager createDirectoryAtPath:[_app.gpxPath stringByAppendingPathComponent:TEMP_DIR]
                                        withIntermediateDirectories:YES
                                                         attributes:nil
                                                              error:&err];
            }
            if (!err)
            {
                [gpxStr writeToFile:finalFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
                if (err)
                    NSLog(@"Error creating gpx file");

                [OAUtilities denyAccessToFile:_importUrl.path removeFromInbox:YES];

                _importUrl = [NSURL fileURLWithPath:finalFilePath];
            }
            if (![NSFileManager.defaultManager fileExistsAtPath:finalFilePath])
            {
                [OAUtilities denyAccessToFile:finalFilePath removeFromInbox:YES];
                _importUrl = nil;
                [OARootViewController showInfoAlertWithTitle:OALocalizedString(@"import_failed")
                                                     message:OALocalizedString(@"import_cannot")
                                                inController:_hostVC];
            }
        }
    }
    else
    {
        [OAUtilities denyAccessToFile:_importUrl.path removeFromInbox:YES];
        _importUrl = nil;
    }
}

- (void) processUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView
{
    _importUrl = [url copy];
    OASGpxDataItem *item;
    
    if ([_importUrl.pathExtension isEqualToString:KML_EXT])
        [self handleKmlImport:[NSData dataWithContentsOfURL:_importUrl]];
    else if ([_importUrl.pathExtension isEqualToString:KMZ_EXT])
        [self handleKmzImport];
    
    // import failed
    if (!_importUrl)
        return;
    
    // Try to import gpx
    __block OASKFile *file = [[OASKFile alloc] initWithFilePath:_importUrl.path];
    _doc = [OASGpxUtilities.shared loadGpxFileFile:file];
    if (_doc)
    {
        // _2024-07-30_.gpx
        NSString *fileName = [_importUrl.path lastPathComponent];
        // 123/_2024-07-30_.gpx
        NSString *importDestFilepath = [_importGpxPath stringByAppendingPathComponent:fileName];
        if ([[OAGPXDatabase sharedDb] containsGPXItem:importDestFilepath])
        {
            if (showAlerts)
            {
                [self showImportGpxAlert:OALocalizedString(@"import_tracks")
                                 message:OALocalizedString(@"gpx_import_already_exists")
                       cancelButtonTitle:OALocalizedString(@"shared_string_cancel")
                       otherButtonTitles:@[OALocalizedString(@"gpx_add_new"), OALocalizedString(@"gpx_overwrite")]
                             openGpxView:openGpxView];
            }
        }
        else
        {
            item = [self doImport];
        }
    }
    else
    {
        _doc = nil;
        _importUrl = nil;
        
        if (showAlerts)
        {
            [self showImportGpxAlert:OALocalizedString(@"import_tracks")
                             message:OALocalizedString(@"gpx_cannot_import")
                   cancelButtonTitle:OALocalizedString(@"shared_string_ok")
                   otherButtonTitles:nil
                         openGpxView:NO];
        }
    }
    
    if (item && openGpxView)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doPush];
            file = item.file;
            auto trackItem = [[OASTrackItem alloc] initWithFile:file];
            trackItem.dataItem = item;
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:trackItem];
        });
    }
}

- (void)prepareProcessUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView completion:(void (^)(BOOL success))completion {
    if ([url isFileURL])
    {
        [self prepareProcessUrl:^{
            [self processUrl:url showAlerts:showAlerts openGpxView:openGpxView];
            if (completion)
                completion(YES);
        }];
    }
}

- (void)prepareProcessUrl:(void (^)(void))processUrl
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self showProgressHUD];
        if (processUrl)
            processUrl();
        [self hideProgressAndRefresh];
    });
}

- (OASGpxDataItem *)doImport
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_importGpxPath])
        [fileManager createDirectoryAtPath:_importGpxPath withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *gpxPath = _newGpxName
        ? [_importGpxPath stringByAppendingPathComponent:_newGpxName]
        : [_importGpxPath stringByAppendingPathComponent:[self getCorrectedFilename:[_importUrl.path lastPathComponent]]];
    [fileManager copyItemAtPath:_importUrl.path
                         toPath:gpxPath
                          error:nil];
    OASGpxDataItem *item = [[OAGPXDatabase sharedDb] addGPXFileToDBIfNeeded:gpxPath];
    if (item.color != 0)
        [[OAGPXAppearanceCollection sharedInstance] getColorItemWithValue:item.color];

    [OAUtilities denyAccessToFile:_importUrl.path removeFromInbox:YES];

    _doc = nil;
    _importUrl = nil;
    _newGpxName = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:OAGPXImportUIHelperDidFinishImportNotification object:nil userInfo:nil];
    });
    return item;
}

- (NSString *)getCorrectedFilename:(NSString *)filename
{
    if ([filename hasSuffix:@".xml"])
        return [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"gpx"];
    else
        return filename;
}

- (void) removeFromDB
{
    NSString *gpxFilePath = [_importUrl.path hasPrefix:_app.gpxPath]
        ? [OAUtilities getGpxShortPath:_importUrl.path]
        : [_importUrl.path lastPathComponent];

    OASGpxDataItem *item = [[OAGPXDatabase sharedDb] getGPXItemByFileName:gpxFilePath];
    if (item)
        [[OAGPXDatabase sharedDb] removeGpxItem:item withLocalRemove:YES];
    else
        NSLog(@"[OAGPXImportUIHelper] -> [ERROR] -> removeFromDB");
}

#pragma mark - OAGPXImportDelegate

- (void)hideProgressAndRefresh
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD];
    });
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count == 0)
        return;
    
    NSURL *url = urls.firstObject;
    NSString *path = url.path;
    NSString *ext = [path pathExtension].lowerCase;
    if ([ext isEqualToString:GPX_EXT]
        || [ext isEqualToString:KML_EXT]
        || [ext isEqualToString:KMZ_EXT])
    {
        [self processUrl:url showAlerts:YES openGpxView:NO];
    }
}

@end
