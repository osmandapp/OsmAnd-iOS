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

#import "OAGPXTableViewCell.h"
#import "OAGPXRecTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OASettingSwitchCell.h"
#import "OAIconTextCollapseCell.h"

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
#import "OAGPXRouteTableViewCell.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAKml2Gpx.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"
#import "OAUtilities.h"
#import "PXAlertView.h"
#import "OAPluginsViewController.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAImportGPXBottomSheetViewController.h"
#import <MBProgressHUD.h>

#import "OATrackIntervalDialogView.h"

#include <OsmAndCore/ArchiveReader.h>


#define _(name) OAGPXListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4
#define kAlertViewCancelButtonIndex -1
#define kMaxCancelButtonWidth 100
#define kIconTitleValueCell @"OAIconTitleValueCell"
#define kCellTypeSwitch @"OASettingSwitchCell"
#define kCellTypeGPX @"OAGPXTableViewCell"
#define kCellTypeTrackRecord @"OAIconTextCollapseCell"
#define kCellMenu @"OAIconTextTableViewCell"

#define GPX_EXT @"gpx"
#define KML_EXT @"kml"
#define KMZ_EXT @"kmz"

typedef enum
{
    kActiveTripsMode = 0,
    kAllTripsMode
    
} kGpxListMode;

typedef enum
{
    kGPXCellTypeItem = 0,
    kGPXCellTypeMenu
    
} kGpxCellType;

@interface OAGpxTableGroup : NSObject
    @property NSString *type;
    @property BOOL isOpen;
    @property NSString *groupName;
    @property NSMutableArray *groupItems;
    @property NSString *groupIcon;
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
    kGpxListMode _viewMode;

    NSURL *_importUrl;
    OAGPXDocument *_doc;
    NSString *_newGpxName;

    NSInteger _selectedIndex;
    
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

    OAGPXRecTableViewCell* _recCell;
    OAAutoObserverProxy* _trackRecordingObserver;

    NSInteger _recSectionIndex;
    NSInteger _routeSectionIndex;
    NSInteger _tripsSectionIndex;
    //NSInteger _createTripSectionIndex;
    //NSInteger _menuSectionIndex;
    NSArray *_data;
    
    CALayer *_horizontalLine;
    
    BOOL _editActive;
    NSArray *_visible;
    BOOL _isRouteActive;
    OAGPX* _routeItem;
    
    MBProgressHUD *_progressHUD;
    
    OAAutoObserverProxy* _gpxRouteCanceledObserver;
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

- (void) removeFromDB
{
    [[OAGPXDatabase sharedDb] removeGpxItem:[_importUrl.path lastPathComponent]];
    [[OAGPXDatabase sharedDb] save];
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
                    if (![fileMan fileExistsAtPath:[_app.gpxPath stringByAppendingPathComponent:newName]])
                        break;
                }
                
                _newGpxName = [newName copy];
                
                [self doImport:YES];
            });
        };
        
        id overwriteHandler = ^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _newGpxName = nil;
                [self removeFromDB];
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

- (void) processUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView
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
    BOOL exists = [[OAGPXDatabase sharedDb] containsGPXItem:[_importUrl.path lastPathComponent]];
    
    _doc = [[OAGPXDocument alloc] initWithGpxFile:_importUrl.path];
    if (_doc) {
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
                [[NSFileManager defaultManager] removeItemAtPath:[_app.gpxPath stringByAppendingPathComponent:[_importUrl.path lastPathComponent]] error:nil];
                [self removeFromDB];
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
                [[OARootViewController instance].mapPanel openTargetViewWithGPX:item pushed:YES];
        });
    }
}

-(void)processUrl:(NSURL*)url openGpxView:(BOOL)openGpxView
{
    if ([url isFileURL])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self showProgressHUD];
            [self processUrl:url showAlerts:YES openGpxView:openGpxView];
            [self hideProgressAndRefresh];
        });
    }
}

-(void)processUrl:(NSURL*)url
{
    [self processUrl:url openGpxView:YES];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _iapHelper = [OAIAPHelper sharedInstance];
    _savingHelper = [OASavingTrackHelper sharedInstance];
}

-(OAGPX *)doImport:(BOOL)doRefresh
{
    OAGPX *item;
    if (_newGpxName) {
        [[NSFileManager defaultManager] moveItemAtPath:_importUrl.path toPath:[_app.gpxPath stringByAppendingPathComponent:_newGpxName] error:nil];
    } else {
        [[NSFileManager defaultManager] moveItemAtPath:_importUrl.path toPath:[_app.gpxPath stringByAppendingPathComponent:[self getCorrectedFilename:[_importUrl.path lastPathComponent]]] error:nil];
    }
    
    OAGPXTrackAnalysis *analysis = [_doc getAnalysis:0];
    if (_newGpxName) {
        item = [[OAGPXDatabase sharedDb] addGpxItem:_newGpxName title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds analysis:analysis];
    } else {
        item = [[OAGPXDatabase sharedDb] addGpxItem:[self getCorrectedFilename:[_importUrl.path lastPathComponent]] title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds analysis:analysis];
    }
    [[OAGPXDatabase sharedDb] save];
    [[NSFileManager defaultManager] removeItemAtPath:_importUrl.path error:nil];
    
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
- (void)hideProgressAndRefresh {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD];
        [self generateData];
        [self setupView];
    });
}

- (void) importAllGPXFromDocuments
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self showProgressHUD];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
        NSDirectoryEnumerator *enumerator = [fileManager
                                             enumeratorAtURL:documentsURL
                                             includingPropertiesForKeys:keys
                                             options:0
                                             errorHandler:^(NSURL *url, NSError *error) {
                                                 // Return YES for the enumeration to continue after the error.
                                                 return YES;
                                             }];
        for (NSURL *url in enumerator) {
            NSNumber *isDirectory = nil;
            if ([url isFileURL]) {
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
                    [self processUrl:url showAlerts:NO openGpxView:NO];
                }
            }
        }
        [self hideProgressAndRefresh];
    });
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
    
    [self updateButtons];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    [self updateButtons];
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self generateData];
    [self setupView];
    
    _trackRecordingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onTrackRecordingChanged)
                                                         andObserve:_app.trackRecordingObservable];
    _gpxRouteCanceledObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onGpxRouteCanceled)
                                                           andObserve:[OAGPXRouter sharedInstance].routeCanceledObservable];
    
    [self applySafeAreaMargins];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _gpxTableView;
}

- (CGFloat) getToolBarHeight
{
    return self.tabBarController.tabBar.bounds.size.height;
}

- (CGFloat) getNavBarHeight
{
    return navBarWithSegmentControl;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_trackRecordingObserver detach];
    _trackRecordingObserver = nil;

    [_gpxRouteCanceledObserver detach];
    _gpxRouteCanceledObserver = nil;
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
            _recCell.descriptionDistanceView.text = [_app getFormattedDistance:_savingHelper.distance];
            [_recCell setNeedsLayout];
            
            if (!_recCell.btnSaveGpx.enabled && ([_savingHelper hasData]))
                _recCell.btnSaveGpx.enabled = YES;

            _recCell.selectionStyle = ([_savingHelper hasData] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
        }
        
    });
}

- (void) onGpxRouteCanceled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_routeSectionIndex > -1)
        {
            NSInteger prevTripsSectionIndex = _tripsSectionIndex;
            NSInteger prevRouteSectionIndex = _routeSectionIndex;
            NSString *routeFileName = _routeItem.gpxFileName;
            
            [self generateData];
            [self.gpxTableView beginUpdates];

            [self.gpxTableView deleteSections:[NSIndexSet indexSetWithIndex:prevRouteSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            
            if (prevTripsSectionIndex < 0 && _tripsSectionIndex >= 0)
                [self.gpxTableView insertSections:[NSIndexSet indexSetWithIndex:_tripsSectionIndex] withRowAnimation:UITableViewRowAnimationRight];

            [self.gpxList enumerateObjectsUsingBlock:^(OAGPX *item, NSUInteger idx, BOOL *stop)
            {
                if ([item.gpxFileName isEqualToString:routeFileName])
                {
                    [self.gpxTableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:_tripsSectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
                    *stop = YES;
                }
            }];
            
            [self.gpxTableView endUpdates];
        }
        else
        {
            [self generateData];
            [self.gpxTableView reloadData];
        }
    });
}
 
- (void) generateData
{
    self.menuItems = [[NSArray alloc] init];
    NSMutableArray *tableData = [NSMutableArray array];
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    _visible = [OAAppSettings sharedManager].mapSettingVisibleGpx;
    self.gpxList = [NSMutableArray arrayWithArray:db.gpxList];
    
//    NSString *routeFileName = [[OAAppSettings sharedManager] mapSettingActiveRouteFileName];
//    _isRouteActive = (routeFileName != nil);
//    if (_isRouteActive)
//    {
//        _routeItem = [db getGPXItem:routeFileName];
//        for (OAGPX *item in self.gpxList)
//        {
//            if ([item.gpxFileName isEqualToString:routeFileName])
//            {
//                [self.gpxList removeObject:item];
//                break;
//            }
//        }
//    }
//    else
//    {
//        _routeItem = nil;
//    }
    
    if ([_iapHelper.trackRecording isActive])
    {
        [tableData addObject:@[@{
            @"title" : OALocalizedString(@"track_recording_name"),
            @"icon" : @"ic_custom_reverse_direction.png",
            @"type" : kCellTypeTrackRecord }]
        ];
    }
    
    if (self.gpxList.count > 0)
    {
        // Sort items by date-time added desc
        NSArray *sortedArrayGroups = [self.gpxList sortedArrayUsingComparator:^NSComparisonResult(OAGPX* obj1, OAGPX* obj2) {
            return [obj2.importDate compare:obj1.importDate];
        }];
        [_gpxList setArray:sortedArrayGroups];
    }
    
    OAGpxTableGroup* visibleGroup = [[OAGpxTableGroup alloc] init];
    NSMutableArray *visableTracks = [NSMutableArray array];
    visibleGroup.groupName = OALocalizedString(@"tracks_on_map");
    visibleGroup.groupIcon = @"ic_custom_map";
    for (OAGPX *item in _gpxList)
    {
        if ([_visible containsObject:item.gpxFileName])
        {
            [visableTracks addObject:
             @{
                 @"title" : item.gpxTitle,
                 @"icon" : @"ic_custom_trip.png",
                 @"value" : @(YES), // change
                 @"type" : kCellTypeSwitch }
             ];
        }
    }
    visibleGroup.groupItems = [NSMutableArray arrayWithArray:visableTracks];
    visibleGroup.isOpen = visibleGroup.groupItems.count > 1;
    [tableData addObject:visibleGroup];
    
    OAGpxTableGroup* tracksGroup = [[OAGpxTableGroup alloc] init];
    NSMutableArray *allTracks = [NSMutableArray array];
    tracksGroup.groupName = OALocalizedString(@"tracks");
    tracksGroup.groupIcon = @"ic_custom_folder";
    for (OAGPX *item in _gpxList)
    {
        [allTracks addObject:
         @{
             @"title" : item.gpxTitle,
             @"icon" : @"ic_custom_trip.png",
             @"distance" : @"1,33 km",
             @"time" : @"00.00.12",
             @"speed" : @"15 km/h",
             @"type" : kCellTypeGPX }
         ];
    }
    tracksGroup.groupItems = [NSMutableArray arrayWithArray:allTracks];
    tracksGroup.isOpen = NO;
    [tableData addObject:tracksGroup];
    
    // Generate menu items
    self.menuItems = @[@{@"type" : kCellMenu,
                         @"key" : @"import_track",
                         @"title": OALocalizedString(@"gpx_import_title"),
                         @"icon": @"ic_custom_import"},
                       @{@"type" : kCellMenu,
                         @"key" : @"create_new_trip",
                         @"title": OALocalizedString(@"create_new_trip"),
                         @"icon": @"ic_custom_trip.png"}];
    [tableData addObject:self.menuItems];
    _data = [NSMutableArray arrayWithArray:tableData];
}

-(void) setupView {
    
    [self.gpxTableView setDataSource:self];
    [self.gpxTableView setDelegate:self];
    self.gpxTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.gpxTableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) allTripsClicked
{
    [self generateData];
    [_gpxTableView reloadData];
}

- (IBAction) backButtonClicked:(id)sender
{
    [super backButtonClicked:sender];
}

- (IBAction) goRootScreen:(id)sender
{
    if (_popToParent)
        [super backButtonClicked:sender];
    else
        [self.navigationController popToRootViewControllerAnimated:YES];
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
    _editActive = YES;
    [self updateButtons];
    
    [self.gpxTableView beginUpdates];
    for (NSInteger i = 0; i < self.gpxList.count; i++)
    {
        OAGPX *gpx = self.gpxList[i];
        if ([_visible containsObject:gpx.gpxFileName])
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:_tripsSectionIndex];
            [self.gpxTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    if ([OAAppSettings sharedManager].mapSettingShowRecordingTrack)
    {
        [self.gpxTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    
    [self.gpxTableView endUpdates];
    
    [self updateRecButtonsAnimated];
}

- (IBAction) checkButtonClick:(id)sender
{
    NSArray *selectedRows = [self.gpxTableView indexPathsForSelectedRows];
 
    OAAppSettings *settings = [OAAppSettings sharedManager];
    
    NSMutableArray<OAGPX *> *gpxArrHide = [NSMutableArray arrayWithArray:self.gpxList];
    NSMutableArray<OAGPX *> *gpxArrNew = [NSMutableArray array];
    NSMutableArray<NSString *> *gpxFilesHide = [NSMutableArray array];
    NSMutableArray<NSString *> *gpxFilesNew = [NSMutableArray array];
    NSMutableArray<NSIndexPath *> *indexes = [NSMutableArray array];
    
    BOOL currentTripSelected = NO;
    
    for (NSIndexPath *indexPath in selectedRows)
    {
        if (indexPath.section == _recSectionIndex)
            currentTripSelected = YES;
        
        if (indexPath.section != _tripsSectionIndex)
            continue;
        
        OAGPX* gpx = [self.gpxList objectAtIndex:indexPath.row];
        [gpxArrHide removeObject:gpx];
        [gpxArrNew addObject:gpx];
    }

    for (OAGPX *gpx in gpxArrHide)
        [gpxFilesHide addObject:gpx.gpxFileName];
    for (OAGPX *gpx in gpxArrNew)
        [gpxFilesNew addObject:gpx.gpxFileName];

    settings.mapSettingShowRecordingTrack = currentTripSelected;
    
    [settings hideGpx:gpxFilesHide];
    
    for (OAGPX *gpx in gpxArrHide)
    {
        for (NSInteger i = 0; i < self.gpxList.count; i++)
        {
            OAGPX *g = self.gpxList[i];
            if (g == gpx)
                [indexes addObject:[NSIndexPath indexPathForRow:i inSection:1]];
        }
    }
            
    self.gpxList = gpxArrNew;
    
    NSInteger tripsSectionIndex = _tripsSectionIndex;
    
    _visible = [OAAppSettings sharedManager].mapSettingVisibleGpx;

    [self.gpxTableView setEditing:NO animated:YES];
    _editActive = NO;
    [self updateButtons];

    [self generateData];

    [self.gpxTableView beginUpdates];
    
    if (indexes.count > 0)
    {
        if (self.gpxList.count == 0)
            [self.gpxTableView deleteSections:[NSIndexSet indexSetWithIndex:tripsSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        else
            [self.gpxTableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.gpxTableView endUpdates];

    [self updateRecButtonsAnimated];
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
    OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] init];
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"yyyy-MM-dd"];
    
    NSString *fileName = [NSString stringWithFormat:@"Trip_%@.gpx", [fmt stringFromDate:[NSDate date]]];
    NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
    
    NSFileManager *fileMan = [NSFileManager defaultManager];
    if ([fileMan fileExistsAtPath:path])
    {
        NSString *ext = [fileName pathExtension];
        NSString *newName;
        for (int i = 2; i < 100000; i++) {
            newName = [[NSString stringWithFormat:@"%@_(%d)", [fileName stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
            path = [_app.gpxPath stringByAppendingPathComponent:newName];
            if (![fileMan fileExistsAtPath:path])
                break;
        }
    }
    
    [doc saveTo:path];
    
    OAGPXTrackAnalysis *analysis = [doc getAnalysis:0];
    OAGPX* item = [[OAGPXDatabase sharedDb] addGpxItem:[path lastPathComponent] title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds analysis:analysis];
    [[OAGPXDatabase sharedDb] save];
    
    item.newGpx = YES;
    
    [[OAAppSettings sharedManager] showGpx:@[[path lastPathComponent]]];

    [self doPush];
    [[OARootViewController instance].mapPanel openTargetViewWithGPXEdit:item pushed:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    id sectionObject = [_data objectAtIndex:section];
    if ([sectionObject isKindOfClass:NSArray.class] && section != 0)
        return OALocalizedString(@"actions");
    else
        return @"";
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0 && [_iapHelper.trackRecording isActive])
        return 0.01;
    else
        
        return UITableViewAutomaticDimension;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[_data objectAtIndex:section] isKindOfClass:OAGpxTableGroup.class])
    {
        OAGpxTableGroup* groupData = [_data objectAtIndex:section];
        if (groupData.isOpen)
            return [groupData.groupItems count] + 1;
        return 1;
    }
    return [[_data objectAtIndex:section] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id sectionObject = [_data objectAtIndex:indexPath.section];
    if ([sectionObject isKindOfClass:NSArray.class])
    {
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kCellTypeTrackRecord])
        {
            OAIconTextCollapseCell* cell;
            cell = (OAIconTextCollapseCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextCollapseCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCollapseCell" owner:self options:nil];
                cell = (OAIconTextCollapseCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(profile_icon_color_inactive);
                cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.iconView.hidden = NO;
                cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.iconView.tintColor = UIColorFromRGB(color_chart_orange);
                cell.rightIconView.hidden = NO;
                cell.rightIconView.image = [[UIImage imageNamed:@"bg_circle_button_night"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.rightIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            }
            return cell;
        }
        else if ([cellType isEqualToString:kCellMenu])
        {
            static NSString* const reusableIdentifierPoint = @"OAIconTextTableViewCell";
            OAIconTextTableViewCell* cell;
            cell = (OAIconTextTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            }
            if (cell) {
                cell.textView.text = item[@"title"];
                cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                
                cell.arrowIconView.hidden = YES;
            }
            return cell;
        }
    }
    OAGpxTableGroup* groupData = sectionObject;
    if (indexPath.row == 0)
    {
        static NSString* const identifierCell = kIconTitleValueCell;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleValueCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = groupData.groupName;
            
            cell.leftImageView.image = [[UIImage imageNamed:groupData.groupIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftImageView.tintColor = UIColorFromRGB(color_chart_orange);
            cell.descriptionView.text = [NSString stringWithFormat:@"%ld", groupData.groupItems.count];
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
            
            cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            if ([self.gpxTableView isEditing])
                [cell.openCloseGroupButton setHidden:NO];
            else
                [cell.openCloseGroupButton setHidden:YES];
            
            if (groupData.isOpen)
            {
                cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_down"]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_right"]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                if ([cell isDirectionRTL])
                    [cell.iconView setImage:cell.iconView.image.imageFlippedForRightToLeftLayoutDirection];
            }
            cell.iconView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        return cell;
    }
    else
    {
        NSInteger dataIndex = indexPath.row - 1;
        NSDictionary* item = [groupData.groupItems objectAtIndex:dataIndex];
        NSString *cellType = item[@"type"];
        
        if ([cellType isEqualToString:kCellTypeSwitch])
        {
            static NSString* const identifierCell = kCellTypeSwitch;
            OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
                cell.descriptionView.hidden = YES;
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.imgView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
                cell.switchView.on = [item[@"value"] boolValue];
                [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
                cell.imgView.tintColor = UIColorFromRGB(color_chart_orange);
                cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            }
            return cell;
        }
        if ([cellType isEqualToString:kCellTypeGPX])
        {
            static NSString* const identifierCell = kCellTypeGPX;
            OAGPXTableViewCell* cell = [self.gpxTableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXCell" owner:self options:nil];
                cell = (OAGPXTableViewCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.descriptionDistanceView.text = item[@"distance"];
                cell.descriptionPointsView.text = @"0";
                cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_pointer.png"]];
                [cell.iconView setImage:nil];
            }
            return cell;
        }
    }
    return nil;
}

/*
-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self canEditRowAtIndexPath:indexPath];
}
 */

/*
-(BOOL)canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _createTripSectionIndex)
        return NO;
    else if (indexPath.section == _routeSectionIndex)
        return NO;
    else if (indexPath.section == _recSectionIndex && ![_iapHelper.trackRecording isActive])
        return NO;
    else
        return YES;
}
 */

- (void) cancelRoutePressed
{
    [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_cancel_route_q")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                          otherDesc:nil
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 [[OAGPXRouter sharedInstance] cancelRoute];
                             }
                         }];
}

- (void) startStopRecPressed
{
    if ([self.gpxTableView isEditing])
        return;
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL recOn = settings.mapSettingTrackRecording;
    if (recOn)
    {
        settings.mapSettingTrackRecording = NO;
        [self updateRecImg];
    }
    else
    {
        if (![settings.mapSettingSaveTrackIntervalApproved get] && ![_savingHelper hasData])
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
                                         [settings.mapSettingSaveTrackIntervalGlobal set:[settings.trackIntervalArray[[view getInterval]] intValue]];
                                         if (view.swRemember.isOn)
                                             [settings.mapSettingSaveTrackIntervalApproved set:YES];
                                         
                                         settings.mapSettingShowRecordingTrack = view.swShowOnMap.isOn;

                                         settings.mapSettingTrackRecording = YES;
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [self updateRecImg];
                                         });
                                     }
                                 }];
        }
        else
        {
            settings.mapSettingTrackRecording = YES;
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

- (void)updateRecBtn
{
    _recCell.btnSaveGpx.enabled = [_savingHelper hasData];
    _recCell.btnSaveGpx.alpha = ([self.gpxTableView isEditing] ? 0.0 : 1.0);
}

- (void)saveGpxPressed
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
    BOOL wasRecording = [OAAppSettings sharedManager].mapSettingTrackRecording;
    [OAAppSettings sharedManager].mapSettingTrackRecording = NO;
    
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
                                     [OAAppSettings sharedManager].mapSettingTrackRecording = YES;
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [self updateRecImg];
                                     });
                                 }
                             }];
    }
}

#pragma mark - UITableViewDelegate

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
//        if ([_selectedIndexPaths containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
//            [self.gpxTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.gpxTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        //[self selectPreselectedCells:indexPath];
    }
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self.gpxTableView isEditing])
    {
        id sectionObject = [_data objectAtIndex:indexPath.section];
        if ([sectionObject isKindOfClass:NSArray.class])
        {
            NSDictionary *item = _data[indexPath.section][indexPath.row];
            NSString *cellKey = item[@"key"];
            if ([cellKey isEqualToString:@"import_track"])
            {
                [self onImportClicked];
            }
            else if ([cellKey isEqualToString:@"create_new_trip"])
            {
                [self onCreateTrackClicked];
            }
        }
        else if (indexPath.row == 0)
        {
            [self openCloseGroup:indexPath];
        }
        else
        {
            OAGPX* item = [self.gpxList objectAtIndex:indexPath.row - 1];
            [self doPush];
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:item pushed:YES];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    /*
    if (![self.gpxTableView isEditing])
    {
        if (indexPath.section == _recSectionIndex)
        {
            if ([_iapHelper.trackRecording isActive])
            {
                if ([_savingHelper hasData])
                {
                    [self doPush];
                    [[OARootViewController instance].mapPanel openTargetViewWithGPX:nil pushed:YES];
                }
            }
            else
            {
                OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
                pluginsViewController.openFromCustomPlace = YES;
                [self.navigationController pushViewController:pluginsViewController animated:YES];
            }
        }
        else if (indexPath.section == _routeSectionIndex)
        {
            [self doPush];
            [[OARootViewController instance].mapPanel openTargetViewWithGPXRoute:_routeItem pushed:YES];
        }
        else if (indexPath.section == _tripsSectionIndex)
        {
            OAGPX* item = [self.gpxList objectAtIndex:indexPath.row];
            [self doPush];
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:item pushed:YES];
        }
//        else if (indexPath.section == _createTripSectionIndex)
//        {
//            OAGPXMutableDocument *doc = [[OAGPXMutableDocument alloc] init];
//
//            NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
//            [fmt setDateFormat:@"yyyy-MM-dd"];
//
//            NSString *fileName = [NSString stringWithFormat:@"Trip_%@.gpx", [fmt stringFromDate:[NSDate date]]];
//            NSString *path = [_app.gpxPath stringByAppendingPathComponent:fileName];
//
//            NSFileManager *fileMan = [NSFileManager defaultManager];
//            if ([fileMan fileExistsAtPath:path])
//            {
//                NSString *ext = [fileName pathExtension];
//                NSString *newName;
//                for (int i = 2; i < 100000; i++) {
//                    newName = [[NSString stringWithFormat:@"%@_(%d)", [fileName stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
//                    path = [_app.gpxPath stringByAppendingPathComponent:newName];
//                    if (![fileMan fileExistsAtPath:path])
//                        break;
//                }
//            }
//
//            [doc saveTo:path];
//
//            OAGPXTrackAnalysis *analysis = [doc getAnalysis:0];
//            OAGPX* item = [[OAGPXDatabase sharedDb] addGpxItem:[path lastPathComponent] title:doc.metadata.name desc:doc.metadata.desc bounds:doc.bounds analysis:analysis];
//            [[OAGPXDatabase sharedDb] save];
//
//            item.newGpx = YES;
//
//            [[OAAppSettings sharedManager] showGpx:@[[path lastPathComponent]]];
//
//            [self doPush];
//            [[OARootViewController instance].mapPanel openTargetViewWithGPXEdit:item pushed:YES];
//        }
        else
        {
            NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
            SEL action = NSSelectorFromString([item objectForKey:@"action"]);
            [self performSelector:action];
        }
    }
     */
    
    /*
    if (![self.gpxTableView isEditing] || ![self canEditRowAtIndexPath:indexPath])
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
     */
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
