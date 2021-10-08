//
//  OAGPXListViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.12.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAGPXListViewController.h"
#import "OAGPXItemViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OAMapViewController.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OAGpxInfo.h"
#import "OALoadGpxTask.h"

#import "OAGPXRecTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OASettingSwitchCell.h"
#import "OAGPXTrackCell.h"

#import "OsmAndApp.h"
#import "OsmAndCore/GpxDocument.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OASavingTrackHelper.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAKml2Gpx.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"
#import "OAUtilities.h"
#import "PXAlertView.h"
#import "OAPluginsViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OAImportGPXBottomSheetViewController.h"
#import <MBProgressHUD.h>

#import "OATrackIntervalDialogView.h"

#include <OsmAndCore/ArchiveReader.h>


#define _(name) OAGPXListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4
#define kAlertViewCancelButtonIndex -1
#define kMaxCancelButtonWidth 100

#define GPX_EXT @"gpx"
#define KML_EXT @"kml"
#define KMZ_EXT @"kmz"

#define kImportFolderName @"import"

#define kRecordTrackRow 0
#define kRecordTrackSection 0
#define kGPXGroupHeaderRow 0
#define kVisibleTracksWithoutRoutePlanningSection 1
#define kRoutePlanningSection 1

@interface OAGpxTableGroup : NSObject
    @property NSString *type;
    @property BOOL isOpen;
    @property NSString *groupName;
    @property NSMutableArray *groupItems;
    @property NSString *groupIcon;
    @property BOOL isMenu;
    @property NSString *header;
@end

@implementation OAGpxTableGroup

-(id) init {
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OAGPXListViewController ()
{
    NSURL *_importUrl;
    OAGPXDocument *_doc;
    NSString *_newGpxName;
    BOOL _popToParent;
}

@property (strong, nonatomic) NSMutableArray* gpxList;
@property (strong, nonatomic) NSArray* menuItems;
@property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OAGPXListViewController
{
    OsmAndAppInstance _app;
    OASavingTrackHelper *_savingHelper;
    OAIAPHelper *_iapHelper;
    OAAppSettings *_settings;

    OAGPXRecTableViewCell* _recCell;
    OAAutoObserverProxy* _trackRecordingObserver;

    NSArray *_data;
    NSMutableArray<NSIndexPath *> *_selectedIndexPaths;
    NSMutableArray<OAGPX *> *_selectedItems;
    NSMutableArray<OAGpxInfo *> *_gpxList;
    NSMutableDictionary<NSString *, NSArray<OAGpxInfo *> *> *_gpxFolders;
    
    CALayer *_horizontalLine;
    
    BOOL _editActive;
    NSArray *_visible;
    
    NSString *_importGpxPath;
    
    MBProgressHUD *_progressHUD;
}

static UIViewController *parentController;

+ (BOOL) popToParent
{
    if (!parentController)
        return NO;
    
    [OAGPXListViewController doPop];
    
    return YES;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithActiveTrips;
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithAllTrips;
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) removeFromDB:(BOOL)removeFile
{
    NSString *gpxFilePath = [OAUtilities getGpxShortPath:_importUrl.path];
    [[OAGPXDatabase sharedDb] removeGpxItem:gpxFilePath removeFile:removeFile];
}

- (void) setShouldPopToParent:(BOOL)shouldPop
{
    _popToParent = shouldPop;
}

- (void) showImportGpxAlert:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray <NSString *> *) otherButtonTitles {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        id createCopyHandler = ^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSFileManager *fileMan = [NSFileManager defaultManager];
                NSString *ext = [_importUrl.path pathExtension];
                NSString *newName;
                for (int i = 2; i < 100000; i++) {
                    newName = [[NSString stringWithFormat:@"%@_%d", [[_importUrl.path lastPathComponent] stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
                    if (![fileMan fileExistsAtPath:[_importGpxPath stringByAppendingPathComponent:newName]])
                        break;
                }
                
                _newGpxName = [newName copy];
                
                [self doImport:YES];
            });
        };
        
        id overwriteHandler = ^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _newGpxName = nil;
                [self removeFromDB:YES];
                [self doImport:YES];
            });
        };
        
        for (NSInteger i = 0; i < otherButtonTitles.count; i++)
        {
            [alert addAction:[UIAlertAction actionWithTitle:otherButtonTitles[i] style:UIAlertActionStyleDefault handler:i == 0 ? createCopyHandler : overwriteHandler]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [[NSFileManager defaultManager] removeItemAtPath:_importUrl.path error:nil];
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
        [fileManager removeItemAtPath:_importUrl.path error:nil];
        _importUrl = nil;
    }
    [fileManager removeItemAtPath:tmpKmzPath error:nil];
}

- (void) handleKmlImport:(NSData *)data
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (data && data.length > 0)
    {
        NSString *gpxStr = [OAKml2Gpx toGpx:data];
        if (gpxStr)
        {
            NSURL *rootUrl = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSString *finalFilePath = [[rootUrl.path stringByAppendingPathComponent:[_importUrl.lastPathComponent stringByDeletingPathExtension]] stringByAppendingPathExtension:GPX_EXT];
            NSError *err;
            [gpxStr writeToFile:finalFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
            if (err)
                NSLog(@"Error creating gpx file");
            
            [fileManager removeItemAtPath:_importUrl.path error:nil];
            _importUrl = [NSURL fileURLWithPath:finalFilePath];
        }
    }
    else
    {
        _importUrl = nil;
    }
}

- (void) processUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView onComplete:(void (^)(void))onComplete
{
    _importUrl = [url copy];
    OAGPX *item;
    
    if ([_importUrl.pathExtension isEqualToString:KML_EXT])
        [self handleKmlImport:[NSData dataWithContentsOfURL:_importUrl]];
    else if ([_importUrl.pathExtension isEqualToString:KMZ_EXT])
        [self handleKmzImport];
    
    // improt failed
    if (!_importUrl)
        return;
    
    // Try to import gpx
    BOOL exists = [[OAGPXDatabase sharedDb] containsGPXItemByFileName:_importUrl.path.lastPathComponent];    
    _doc = [[OAGPXDocument alloc] initWithGpxFile:_importUrl.path];
    if (_doc)
    {
        if (exists)
        {
            if (showAlerts)
            {
                [self showImportGpxAlert:OALocalizedString(@"gpx_import_title")
                                 message:OALocalizedString(@"gpx_import_already_exists")
                       cancelButtonTitle:OALocalizedString(@"shared_string_cancel")
                       otherButtonTitles:@[OALocalizedString(@"gpx_add_new"), OALocalizedString(@"gpx_overwrite")]];
            }
            else
            {
                if (![_importUrl.path hasPrefix:_app.gpxPath])
                    [[NSFileManager defaultManager] removeItemAtPath:[_importGpxPath stringByAppendingPathComponent:[_importUrl.path lastPathComponent]] error:nil];
                [self removeFromDB:![_importUrl.path hasPrefix:_app.gpxPath]];
                item = [self doImport:NO];
            }
        }
        else
        {
            item = [self doImport:NO];
        }
    }
    else
    {
        _doc = nil;
        _importUrl = nil;
        
        if (showAlerts)
        {
            [self showImportGpxAlert:OALocalizedString(@"gpx_import_title")
                             message:OALocalizedString(@"gpx_cannot_import")
                   cancelButtonTitle:OALocalizedString(@"shared_string_ok")
                   otherButtonTitles:nil];
        }
    }
    
    if (item && openGpxView)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self doPush];
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:item];
        });
    }
    if (onComplete)
        onComplete();
}

- (void)prepareProcessUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView onComplete:(void (^)(void))onComplete
{
    if ([url isFileURL])
    {
        [self prepareProcessUrl:^{
            [self processUrl:url showAlerts:showAlerts openGpxView:openGpxView onComplete:onComplete];
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

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _importGpxPath = [_app.gpxPath stringByAppendingPathComponent:kImportFolderName];
    _iapHelper = [OAIAPHelper sharedInstance];
    _savingHelper = [OASavingTrackHelper sharedInstance];
    _settings = [OAAppSettings sharedManager];
}

-(OAGPX *)doImport:(BOOL)doRefresh
{
    OAGPX *item;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_importGpxPath])
        [fileManager createDirectoryAtPath:_importGpxPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (_newGpxName) {
        [fileManager moveItemAtPath:_importUrl.path toPath:[_importGpxPath stringByAppendingPathComponent:_newGpxName] error:nil];
    } else {
        [fileManager moveItemAtPath:_importUrl.path toPath:[_importGpxPath stringByAppendingPathComponent:[self getCorrectedFilename:[_importUrl.path lastPathComponent]]] error:nil];
    }
    
    OAGPXTrackAnalysis *analysis = [_doc getAnalysis:0];
    if (_newGpxName) {
        NSString *storingPathInFolder = [kImportFolderName stringByAppendingPathComponent:_newGpxName];
        item = [[OAGPXDatabase sharedDb] addGpxItem:storingPathInFolder title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds analysis:analysis];
    } else {
        NSString *name = [self getCorrectedFilename:[_importUrl.path lastPathComponent]];
        NSString *storingPathInFolder = [kImportFolderName stringByAppendingPathComponent:name];
        item = [[OAGPXDatabase sharedDb] addGpxItem:storingPathInFolder title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds analysis:analysis];
    }
    [[OAGPXDatabase sharedDb] save];
    if (![_importUrl.path hasPrefix:_app.gpxPath])
        [fileManager removeItemAtPath:_importUrl.path error:nil];
    
    _doc = nil;
    _importUrl = nil;
    _newGpxName = nil;
    
    if (doRefresh) {
        [self generateData];
        [self setupView];
    }
    return item;
}

- (NSString *)getCorrectedFilename:(NSString *)filename
{
    if ([filename hasSuffix:@".xml"])
        return [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"gpx"];
    else
        return filename;
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
        UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
        _progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        _progressHUD.minShowTime = .5f;
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

#pragma mark - OAGPXImportDelegate

- (void)hideProgressAndRefresh
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD];
        [self generateData];
        [self setupView];
    });
}

- (void)importAllGPXFromDocuments
{
    [self prepareProcessUrl:^{
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSArray *paths = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
            NSURL *documentsURL = [paths lastObject];
            NSArray *keys = @[NSURLIsDirectoryKey];
            NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtURL:documentsURL
                                                  includingPropertiesForKeys:keys
                                                                     options:0
                                                                errorHandler:^(NSURL *url, NSError *error) {
                // Return YES for the enumeration to continue after the error.
                return YES;
            }];

            for (NSURL *url in enumerator)
            {
                NSNumber *isDirectory = nil;
                if ([url isFileURL])
                {
                    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
                    if ([isDirectory boolValue])
                    {
                        [enumerator skipDescendants];
                    }
                    else if (![isDirectory boolValue] &&
                            ([url.pathExtension.lowercaseString isEqualToString:GPX_EXT] ||
                                    [url.pathExtension.lowercaseString isEqualToString:KML_EXT] ||
                                    [url.pathExtension.lowercaseString isEqualToString:KMZ_EXT]) &&
                            ![url.lastPathComponent isEqualToString:@"favourites.gpx"])
                    {
                        [self processUrl:url showAlerts:NO openGpxView:NO onComplete:nil];
                    }
                }
            }
    }];
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"menu_my_trips");
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    
    _editActive = NO;

    self.mapButton.frame = self.checkButton.frame;
    CGRect frame = self.backButton.frame;
    frame.size.width =  kMaxCancelButtonWidth;
    self.cancelButton.frame = frame;
    [self setupView];
    
    _selectedIndexPaths = [[NSMutableArray alloc] init];
    _selectedItems = [[NSMutableArray alloc] init];
    _gpxFolders = [NSMutableDictionary dictionary];
    
    [self updateButtons];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    [self updateButtons];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadData];
    
    _trackRecordingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onTrackRecordingChanged)
                                                         andObserve:_app.trackRecordingObservable];
    [self applySafeAreaMargins];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_trackRecordingObserver detach];
    _trackRecordingObserver = nil;
}

- (void) updateButtons
{
    self.backButton.hidden = _editActive;
    self.cancelButton.hidden = !_editActive;
    self.mapButton.hidden = _editActive;
    self.checkButton.hidden = !_editActive;
}

- (void) onTrackRecordingChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_recCell)
        {
            _recCell.descriptionPointsView.text = [NSString stringWithFormat:@"%d %@", _savingHelper.points, [OALocalizedString(@"gpx_points") lowercaseStringWithLocale:[NSLocale currentLocale]]];
            _recCell.descriptionDistanceView.text = [OAOsmAndFormatter getFormattedDistance:_savingHelper.distance];
            [_recCell setNeedsLayout];
            
            if (!_recCell.btnSaveGpx.enabled && ([_savingHelper hasData]))
                _recCell.btnSaveGpx.enabled = YES;

            _recCell.selectionStyle = ([_savingHelper hasData] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
        }
        
    });
}

- (void) reloadData
{
    OALoadGpxTask *task = [[OALoadGpxTask alloc] init];
    [task execute:^(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>* gpxFolders) {
        _gpxFolders = [NSMutableDictionary dictionaryWithDictionary:gpxFolders];
        [self generateData];
        [self.gpxTableView reloadData];
    }];
}

- (void) onGpxRouteCanceled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.gpxTableView reloadData];
    });
}

- (void) generateData
{
    self.menuItems = [[NSArray alloc] init];
    NSMutableArray *tableData = [NSMutableArray array];
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    _visible = _settings.mapSettingVisibleGpx.get;
    self.gpxList = [NSMutableArray arrayWithArray:db.gpxList];
    
    OAGpxTableGroup *trackRecordingGroup = [[OAGpxTableGroup alloc] init];
    trackRecordingGroup.isMenu = YES;
    trackRecordingGroup.type = [OAIconTextTableViewCell getCellIdentifier];
    trackRecordingGroup.header = OALocalizedString(@"record_trip");
    
    if ([_iapHelper.trackRecording isActive])
        [trackRecordingGroup.groupItems addObject:@{
            @"title" : OALocalizedString(@"track_recording_name"),
            @"icon" : @"ic_custom_reverse_direction.png",
            @"type" : [OAGPXRecTableViewCell getCellIdentifier],
            @"key" : @"track_recording"}
        ];
    else
        [trackRecordingGroup.groupItems addObject:@{
            @"title" : OALocalizedString(@"track_rec_addon_q"),
            @"type" : [OAMenuSimpleCellNoIcon getCellIdentifier],
            @"key" : @"track_recording"}
        ];
    [tableData addObject:trackRecordingGroup];
    
    if (self.gpxList.count > 0)
    {
        // Sort items by date-time added desc
        NSArray *sortedArrayGroups = [self.gpxList sortedArrayUsingComparator:^NSComparisonResult(OAGPX* obj1, OAGPX* obj2) {
            return [obj2.importDate compare:obj1.importDate];
        }];
        [self.gpxList setArray:sortedArrayGroups];
    }
    
    OAGpxTableGroup* visibleGroup = [[OAGpxTableGroup alloc] init];
    visibleGroup.groupName = OALocalizedString(@"tracks_on_map");
    visibleGroup.groupIcon = @"ic_custom_map";
    visibleGroup.isMenu = NO;
    visibleGroup.type = kGPXGroupHeaderRow;
    visibleGroup.header = @"";
    for (OAGPX *item in _gpxList)
    {
        if ([_visible containsObject:item.gpxFilePath])
        {
            [visibleGroup.groupItems addObject:
             @{
                 @"title" : [item getNiceTitle],
                 @"icon" : @"ic_custom_trip.png",
                 @"track" : item,
                 @"type" : [OASettingSwitchCell getCellIdentifier],
                 @"key" : @"track_group"}];
        }
    }
    visibleGroup.isOpen = YES;
    if (visibleGroup.groupItems.count > 0)
        [tableData addObject:visibleGroup];
    
    for (NSString *key in _gpxFolders.allKeys)
    {
        OAGpxTableGroup* tracksGroup = [[OAGpxTableGroup alloc] init];
        tracksGroup.groupName = [OALocalizedString(key) capitalizedString];
        tracksGroup.groupIcon = @"ic_custom_folder";
        tracksGroup.isMenu = NO;
        tracksGroup.type = kGPXGroupHeaderRow;
        tracksGroup.header = @"";
        for (OAGpxInfo *track in _gpxFolders[key])
        {
            if (!track.gpx)
                continue;
            
            [tracksGroup.groupItems addObject:@{
                @"type" : [OAGPXTrackCell getCellIdentifier],
                @"title" : [track getName],
                @"track" : track.gpx,
                @"distance" : [OAOsmAndFormatter getFormattedDistance:track.gpx.totalDistance],
                @"time" : [OAOsmAndFormatter getFormattedTimeInterval:track.gpx.timeSpan shortFormat:YES],
                @"wpt" : [NSString stringWithFormat:@"%d", track.gpx.wptPoints],
                @"key" : @"track_group"
            }];
        }
        tracksGroup.isOpen = NO;
        if (tracksGroup.groupItems.count > 0)
            [tableData addObject:tracksGroup];
    }
    
    // Generate menu items
    OAGpxTableGroup* actionsGroup = [[OAGpxTableGroup alloc] init];
    actionsGroup.isMenu = YES;
    actionsGroup.type = [OAIconTextTableViewCell getCellIdentifier];
    actionsGroup.header = OALocalizedString(@"actions");
    self.menuItems = @[@{@"type" : [OAIconTextTableViewCell getCellIdentifier],
                         @"key" : @"import_track",
                         @"title": OALocalizedString(@"gpx_import_title"),
                         @"icon": @"ic_custom_import",
                         @"header" : OALocalizedString(@"actions")},
                       @{@"type" : [OAIconTextTableViewCell getCellIdentifier],
                         @"key" : @"create_new_trip",
                         @"title": OALocalizedString(@"create_new_trip"),
                         @"icon": @"ic_custom_trip.png"}];
    actionsGroup.groupItems = [NSMutableArray arrayWithArray:self.menuItems];
    
    [tableData addObject:actionsGroup];
    _data = [NSMutableArray arrayWithArray:tableData];
}

-(void) setupView {
    
    [self.gpxTableView setDataSource:self];
    [self.gpxTableView setDelegate:self];
    self.gpxTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.gpxTableView reloadData];
    self.gpxTableView.allowsMultipleSelectionDuringEditing = YES;
    
}

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions


- (IBAction) backButtonClicked:(id)sender
{
    [super backButtonClicked:sender];
}

- (IBAction) goRootScreen:(id)sender
{
    if (_popToParent)
    {
        [super backButtonClicked:sender];
    }
    else
    {
        [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void) updateRecButtonsAnimated
{
    [UIView animateWithDuration:.3 animations:^{
        if (_recCell)
        {
            [self updateRecImg];
            [self updateRecBtn];
        }
    }];
}

- (IBAction) mapButtonClick:(id)sender
{
    [self.gpxTableView setEditing:YES animated:YES];
    [self.gpxTableView reloadData];
    [self updateButtons];
    
    _editActive = YES;
    [self updateButtons];
    [self updateRecButtonsAnimated];
}

- (IBAction) checkButtonClick:(id)sender
{
    NSMutableArray<OAGPX *> *gpxArrHide = [NSMutableArray arrayWithArray:self.gpxList];
    NSMutableArray<OAGPX *> *gpxArrNew = [NSMutableArray array];
    NSMutableArray<NSString *> *gpxFilesHide = [NSMutableArray array];
    NSMutableArray<NSString *> *gpxFilesNew = [NSMutableArray array];
    
    BOOL currentTripSelected = [self.gpxTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:0]];
    
    for (OAGPX *gpx in _selectedItems)
    {
        [gpxArrHide removeObject:gpx];
        [gpxArrNew addObject:gpx];
    }
    for (OAGPX *gpx in gpxArrHide)
        [gpxFilesHide addObject:gpx.gpxFilePath];
    for (OAGPX *gpx in gpxArrNew)
        [gpxFilesNew addObject:gpx.gpxFilePath];

    [_settings.mapSettingShowRecordingTrack set:currentTripSelected];
    [_settings hideGpx:gpxFilesHide];
    [_settings showGpx:gpxFilesNew];
    
    self.gpxList = gpxArrNew;
    [_settings updateGpx:gpxFilesNew];
    
    [self.gpxTableView setEditing:NO animated:NO];
    _editActive = NO;
    [_selectedItems removeAllObjects];
    [_selectedIndexPaths removeAllObjects];
    [self updateButtons];
    
    [self generateData];
    [self updateRecButtonsAnimated];
    [self.gpxTableView reloadData];
}

- (IBAction) cancelButtonClick:(id)sender
{
    [self.gpxTableView setEditing:NO animated:YES];
    _editActive = NO;
    [self updateButtons];
    [self updateRecButtonsAnimated];
}

- (void) onImportClicked
{
//    NSString* favoritesImportText = OALocalizedString(@"gpx_import_desc");
//    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
//    [importHelpAlert show];
    OAImportGPXBottomSheetViewController *controller = [[OAImportGPXBottomSheetViewController alloc] initWithParam:self];
    [controller show];
}

- (void) onCreateTrackClicked
{
    [self dismissViewController];
    [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] init]];
}

- (void) startStopRecPressed
{
    if ([self.gpxTableView isEditing])
        return;
    
    BOOL recOn = _settings.mapSettingTrackRecording;
    if (recOn)
    {
        _settings.mapSettingTrackRecording = NO;
        [self updateRecImg];
    }
    else
    {
        if (![_settings.mapSettingSaveTrackIntervalApproved get] && ![_savingHelper hasData])
        {
            OATrackIntervalDialogView *view = [[OATrackIntervalDialogView alloc] initWithFrame:CGRectMake(0.0, 0.0, 252.0, 176.0)];
            
            [PXAlertView showAlertWithTitle:OALocalizedString(@"track_start_rec")
                                    message:nil
                                cancelTitle:OALocalizedString(@"shared_string_cancel")
                                 otherTitle:OALocalizedString(@"shared_string_ok")
                                  otherDesc:nil
                                 otherImage:nil
                                contentView:view
                                 completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                     
                                     if (!cancelled)
                                     {
                                         [_settings.mapSettingSaveTrackIntervalGlobal set:[_settings.trackIntervalArray[[view getInterval]] intValue]];
                                         if (view.swRemember.isOn)
                                             [_settings.mapSettingSaveTrackIntervalApproved set:YES];

                                         [_settings.mapSettingShowRecordingTrack set:view.swShowOnMap.isOn];

                                         _settings.mapSettingTrackRecording = YES;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [self updateRecImg];
                                         });
                                     }
                                 }];
        }
        else
        {
            _settings.mapSettingTrackRecording = YES;
            [self updateRecImg];
        }
    }
}

- (void) updateRecImg
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL recOn = settings.mapSettingTrackRecording;
    if (recOn)
    {
        [_recCell.btnStartStopRec setImage:[UIImage imageNamed:@"ic_action_rec_stop.png"] forState:UIControlStateNormal];
        _recCell.btnStartStopRec.tintColor = [UIColor blackColor];
    }
    else
    {
        [_recCell.btnStartStopRec setImage:[UIImage imageNamed:@"ic_action_rec_start.png"] forState:UIControlStateNormal];
        _recCell.btnStartStopRec.tintColor = [UIColor redColor];
    }
    
    _recCell.btnStartStopRec.alpha = ([self.gpxTableView isEditing] ? 0.0 : 1.0);
}

- (void) updateRecBtn
{
    _recCell.btnSaveGpx.enabled = [_savingHelper hasData];
    _recCell.btnSaveGpx.alpha = ([self.gpxTableView isEditing] ? 0.0 : 1.0);
}

- (void) saveGpxPressed
{
    if ([self.gpxTableView isEditing])
        return;

    if ([_savingHelper hasDataToSave] && _savingHelper.distance < 10.0)
    {
        [PXAlertView showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_no")
                             otherTitle:OALocalizedString(@"shared_string_yes")
                              otherDesc:nil
                             otherImage:nil
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled) {
                                     [self doSaveTrack];
                                 }
                             }];
    }
    else
    {
        [self doSaveTrack];
    }
}

- (void) doSaveTrack
{
    BOOL wasRecording = _settings.mapSettingTrackRecording;
    _settings.mapSettingTrackRecording = NO;
    
    if ([_savingHelper hasDataToSave])
        [_savingHelper saveDataToGpx];
    
    [self updateRecBtn];
    
    [self generateData];
    [self setupView];
    
    if (wasRecording)
    {
        [PXAlertView showAlertWithTitle:OALocalizedString(@"track_continue_rec_q")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_no")
                             otherTitle:OALocalizedString(@"shared_string_yes")
                              otherDesc:nil
                             otherImage:nil
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled) {
                                     _settings.mapSettingTrackRecording = YES;
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [self updateRecImg];
                                     });
                                 }
                             }];
    }
    [self reloadData];
}

- (BOOL) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    NSInteger dataIndex = indexPath.row - 1;
    OAGpxTableGroup *groupData = [_data objectAtIndex:indexPath.section];
    NSDictionary* item = [groupData.groupItems objectAtIndex:dataIndex];
    OAGPX *gpx = item[@"track"];
    if (sw.isOn)
        [_settings showGpx:@[gpx.gpxFilePath] update:NO];
    else if ([_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath])
        [_settings hideGpx:@[gpx.gpxFilePath] update:NO];
    [self.gpxTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.gpxTableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [self.gpxTableView numberOfSections] - 1)] withRowAnimation:UITableViewRowAnimationNone];
    return NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:section];
    return groupData.header;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:section];
    if (groupData.isMenu)
        return 48.;
    else
        return 24.;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:section];
    if (groupData.isMenu)
        return groupData.groupItems.count;
    else if (groupData.isOpen)
        return [groupData.groupItems count] + 1;
    return 1;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.gpxTableView.isEditing && [self.gpxTableView.indexPathsForSelectedRows containsObject:indexPath])
    {
        [cell setSelected:YES];
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxTableGroup *item = [_data objectAtIndex:indexPath.section];
    if (item.isMenu)
    {
        NSDictionary *menuItem = item.groupItems[indexPath.row];
        NSString *menuCellType = menuItem[@"type"];
        if ([menuCellType isEqualToString:[OAGPXRecTableViewCell getCellIdentifier]])
        {
            if (!_recCell)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAGPXRecTableViewCell getCellIdentifier] owner:self options:nil];
                _recCell = (OAGPXRecTableViewCell *)[nib objectAtIndex:0];
            }
            if (_recCell)
            {
                [_recCell.textView setText:OALocalizedString(@"track_recording_name")];
                
                _recCell.descriptionPointsView.text = [NSString stringWithFormat:@"%d %@", _savingHelper.points, [OALocalizedString(@"gpx_waypoints") lowercaseStringWithLocale:[NSLocale currentLocale]]];
                _recCell.descriptionDistanceView.text = [OAOsmAndFormatter getFormattedDistance:_savingHelper.distance];
                
                [_recCell.btnStartStopRec removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [_recCell.btnStartStopRec addTarget:self action:@selector(startStopRecPressed) forControlEvents:UIControlEventTouchUpInside];
                [_recCell.btnSaveGpx removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [_recCell.btnSaveGpx addTarget:self action:@selector(saveGpxPressed) forControlEvents:UIControlEventTouchUpInside];
                
                [self updateRecImg];
                [self updateRecBtn];
            }
            return _recCell;
        }
        else if ([menuCellType isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
        {
            OAMenuSimpleCellNoIcon *cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCellNoIcon getCellIdentifier] owner:self options:nil];
                cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
                cell.descriptionView.hidden = YES;
                cell.textView.font = [UIFont systemFontOfSize:14.0];
                cell.textView.textColor = [UIColor darkGrayColor];
            }
            if (cell)
                [cell.textView setText:OALocalizedString(@"track_rec_addon_q")];
            return cell;
        }
        else if ([menuCellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
        {
            OAIconTextTableViewCell* cell;
            cell = (OAIconTextTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            }
            if (cell) {
                cell.textView.text = menuItem[@"title"];
                cell.iconView.image = [UIImage templateImageNamed:menuItem[@"icon"]];
                cell.arrowIconView.hidden = YES;
            }
            return cell;
        }
    }
    else {
        if (indexPath.row == kGPXGroupHeaderRow)
        {
            OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
                cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                cell.textView.text = item.groupName;
                
                cell.leftIconView.image = [UIImage templateImageNamed:item.groupIcon];
                cell.leftIconView.tintColor = UIColorFromRGB(color_chart_orange);
                cell.descriptionView.text = [NSString stringWithFormat:@"%ld", item.groupItems.count];
                cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
                
                cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
                [cell.openCloseGroupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                if ([self.gpxTableView isEditing])
                    [cell.openCloseGroupButton setHidden:NO];
                else
                    [cell.openCloseGroupButton setHidden:YES];
                
                if (item.isOpen)
                {
                    cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_down"];
                }
                else
                {
                    cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
                    if ([cell isDirectionRTL])
                        [cell.rightIconView setImage:cell.rightIconView.image.imageFlippedForRightToLeftLayoutDirection];
                }
                cell.rightIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            }
            return cell;
        }
        else
        {
            NSInteger dataIndex = indexPath.row - 1;
            NSDictionary *groupItem = item.groupItems[dataIndex];
            NSString *cellType = groupItem[@"type"];
            OAGPX *gpx = groupItem[@"track"];
            if ([cellType isEqualToString:[OASettingSwitchCell getCellIdentifier]])
            {
                OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
                    cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
                    cell.descriptionView.hidden = YES;
                    cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                }
                if (cell)
                {
                    cell.textView.text = groupItem[@"title"];
                    cell.imgView.image = [UIImage templateImageNamed:groupItem[@"icon"]];
                    [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    cell.switchView.on = [_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath];
                    [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
                    cell.imgView.tintColor = [_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
                    cell.switchView.tag = indexPath.section << 10 | indexPath.row;
                }
                return cell;
            }
            if ([cellType isEqualToString:[OAGPXTrackCell getCellIdentifier]])
            {
                OAGPXTrackCell* cell = nil;
                cell = [tableView dequeueReusableCellWithIdentifier:[OAGPXTrackCell getCellIdentifier]];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAGPXTrackCell getCellIdentifier] owner:self options:nil];
                    cell = (OAGPXTrackCell *)[nib objectAtIndex:0];
                    cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                }
                if (cell)
                {
                    cell.titleLabel.text = groupItem[@"title"];
                    cell.distanceLabel.text = groupItem[@"distance"];
                    cell.timeLabel.text = groupItem[@"time"];
                    cell.wptLabel.text = groupItem[@"wpt"];
                    [cell setRightButtonVisibility:YES];
                    [cell.editButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_right"] forState:UIControlStateNormal];
                    cell.editButton.tintColor = UIColorFromRGB(color_tint_gray);
                    cell.leftIconImageView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
                    cell.leftIconImageView.tintColor = [_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
                }
                return cell;
            }
        }
    }
    return nil;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxTableGroup *groupData = [_data objectAtIndex:indexPath.section];
    if (groupData.isMenu)
    {
        NSDictionary *menuItem = groupData.groupItems[indexPath.row];
        NSString *menuCellType = menuItem[@"key"];
        return  [menuCellType isEqualToString:@"track_recording"] && [_iapHelper.trackRecording isActive];
    }
    else
        return YES;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kRecordTrackSection && indexPath.row == kRecordTrackRow)
        return;
    else if (indexPath.row == kGPXGroupHeaderRow)
        [self deselectAllGroup:indexPath.section];
    else
        [self selectDeselectGroupItem:indexPath select:NO];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxTableGroup *item = [_data objectAtIndex:indexPath.section];
    if (![self.gpxTableView isEditing])
    {
        if (item.isMenu)
        {
            NSDictionary *menuItem = item.groupItems[indexPath.row];
            NSString *menuCellType = menuItem[@"key"];
            if ([menuCellType isEqualToString:@"import_track"])
            {
                [self onImportClicked];
            }
            else if ([menuCellType isEqualToString:@"create_new_trip"])
            {
                [self onCreateTrackClicked];
            }
            else if ([menuCellType isEqualToString:@"track_recording"])
            {
                if ([_iapHelper.trackRecording isActive])
                {
                    if ([_savingHelper hasData])
                    {
                        [self doPush];
                        [[OARootViewController instance].mapPanel openTargetViewWithGPX:nil];
                    }
                }
                else
                {
                    OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
                    [self.navigationController pushViewController:pluginsViewController animated:YES];
                }
            }
        }
        else if (indexPath.row == 0)
        {
            [self openCloseGroup:indexPath];
        }
        else
        {
            NSDictionary *gpxInfo = item.groupItems[indexPath.row - 1];
            OAGPX* gpxItem = gpxInfo[@"track"];
            [self doPush];
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpxItem];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else
    {
        if (indexPath.section == kRecordTrackSection && indexPath.row == kRecordTrackRow)
            return;
        if (indexPath.row == kGPXGroupHeaderRow)
            [self selectAllGroup:indexPath.section];
        else
            [self selectDeselectGroupItem:indexPath select:YES];
    }
}

#pragma mark - Group header methods

- (void) openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    
    [self openCloseGroup:indexPath];
}

- (void) openCloseGroup:(NSIndexPath *)indexPath
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:indexPath.section];
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.gpxTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        if ([_selectedIndexPaths containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
            [self.gpxTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.gpxTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self selectPreselectedCells:indexPath];
    }
}

#pragma mark - Selection methods

- (void) selectAllGroup:(NSInteger)section
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:section];
    if (!groupData.isOpen)
        for (NSInteger row = 1; row <= groupData.groupItems.count; row++)
            [self selectDeselectGroupItem: [NSIndexPath indexPathForRow:row inSection:section] select:YES];
    else
    {
        for (NSUInteger row = 1; row < [self.gpxTableView numberOfRowsInSection:section]; row++)
            [self selectDeselectGroupItem: [NSIndexPath indexPathForRow:row inSection:section] select:YES];
        [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:section]];
    }
}

- (void) deselectAllGroup:(NSInteger)section
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:section];
    if (!groupData.isOpen)
        for (NSInteger row = 1; row <= groupData.groupItems.count; row++)
            [self selectDeselectGroupItem: [NSIndexPath indexPathForRow:row inSection:section] select:NO];
    else
    {
        for (NSUInteger row = 1; row < [self.gpxTableView numberOfRowsInSection:section]; row++)
            [self selectDeselectGroupItem: [NSIndexPath indexPathForRow:row inSection:section] select:NO];
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:section]];
    }
}

- (void) selectDeselectGroupItem:(NSIndexPath *)indexPath select:(BOOL)select
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:indexPath.section];
    NSDictionary *selectedItem = groupData.groupItems[indexPath.row - 1];
    if (select)
        [_selectedItems addObject:selectedItem[@"track"]];
    else
        [_selectedItems removeObject:selectedItem[@"track"]];
    
    NSInteger section = kVisibleTracksWithoutRoutePlanningSection;
    for (OAGpxTableGroup *item in _data)
    {
        if (item.isMenu)
            continue;
        
        OAGpxTableGroup* groupData = (OAGpxTableGroup *)item;
        NSInteger row = 1;
        for (NSDictionary *track in groupData.groupItems)
        {
            OAGPX *gpx = track[@"track"];
            OAGPX *selectedGpx = selectedItem[@"track"];
            if ([gpx.gpxFilePath isEqualToString:selectedGpx.gpxFilePath])
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                if (select)
                {
                    [self addIndexPathToSelectedCellsArray:indexPath];
                    if (groupData.isOpen)
                    {
                        [self.gpxTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                    }
                }
                else
                {
                    if (groupData.isOpen)
                    {
                        [self.gpxTableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                    [self removeIndexPathFromSelectedCellsArray:indexPath];
                }
            }
            row += 1;
        }
        section += 1;
    }
    [self selectDeselectGroupHeader:indexPath select:select];
}

- (void) selectDeselectGroupHeader:(NSIndexPath *)indexPath select:(BOOL)select
{
    NSInteger section = kVisibleTracksWithoutRoutePlanningSection;
    for (; section < [self.gpxTableView numberOfSections] - 1; section++)
    {
        OAGpxTableGroup* groupData = [_data objectAtIndex:section];
        BOOL isGroupHeaderSelected = [self.gpxTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:section]];
        NSInteger numberOfSelectedRowsInSection = 0;
        
        for (NSIndexPath *indexPath in _selectedIndexPaths)
        {
            if (indexPath.section == section && indexPath.row != 0)
                numberOfSelectedRowsInSection++;
        }
        if (select)
        {
            if ((numberOfSelectedRowsInSection == groupData.groupItems.count && !isGroupHeaderSelected) || isGroupHeaderSelected)
            {
                [self.gpxTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
                [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:section]];
            }
        }
        else
        {
            if (indexPath.row == kGPXGroupHeaderRow)
            {
                [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
                [self.gpxTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
            }
            else if (numberOfSelectedRowsInSection != groupData.groupItems.count)
            {
                [self.gpxTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section] animated:YES];
                [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:section]];
            }
        }
    }
}

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
    if (![_selectedIndexPaths containsObject:indexPath])
    {
        [_selectedIndexPaths addObject:indexPath];
    }
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    if ([_selectedIndexPaths containsObject:indexPath])
    {
        [_selectedIndexPaths removeObject:indexPath];
    }
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedIndexPaths)
        if (itemPath.section == indexPath.section)
            [self.gpxTableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)doPush
{
    parentController = self.parentViewController;
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush; // kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromRight; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController popToRootViewControllerAnimated:NO];
}

+ (void)doPop
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal; // kCATransitionMoveIn; //, kCATransitionPush, kCATransitionReveal, kCATransitionFade
    transition.subtype = kCATransitionFromLeft; //kCATransitionFromLeft, kCATransitionFromRight, kCATransitionFromTop, kCATransitionFromBottom
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController pushViewController:parentController animated:NO];
    
    parentController = nil;
}

@end
