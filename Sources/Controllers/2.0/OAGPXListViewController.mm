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

#import "OAGPXTableViewCell.h"
#import "OAGPXRecTableViewCell.h"

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
#import "OAKml2Gpx.h"
#import "ZipArchive.h"

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


#define _(name) OAGPXListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4
#define kAlertViewCancelButtonIndex -1

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


#define GpxTableGroup _(GpxTableGroup)
@interface GpxTableGroup : NSObject
    @property int type;
    @property NSString* groupName;
    @property NSMutableArray*  groupItems;
@end

@implementation GpxTableGroup

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
    UITableViewCell *_addonCell;
    OAAutoObserverProxy* _trackRecordingObserver;

    NSInteger _recSectionIndex;
    NSInteger _routeSectionIndex;
    NSInteger _tripsSectionIndex;
    NSInteger _createTripSectionIndex;
    NSInteger _menuSectionIndex;
    
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
        _viewMode = kActiveTripsMode;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithActiveTrips;
{
    self = [super init];
    if (self)
    {
        _viewMode = kActiveTripsMode;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithAllTrips;
{
    self = [super init];
    if (self)
    {
        _viewMode = kAllTripsMode;
        [self commonInit];
    }
    return self;
}

- (void) removeFromDB
{
    [[OAGPXDatabase sharedDb] removeGpxItem:[_importUrl.path lastPathComponent]];
    [[OAGPXDatabase sharedDb] save];
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
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void) handleKmzImport
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    ZipArchive *zip = [[ZipArchive alloc] init];
    [zip UnzipOpenFile:_importUrl.path];
    NSDictionary *result = [zip UnzipFileToMemory];
    if (result && result.count == 1)
    {
        [self handleKmlImport:result.allValues.firstObject];
    }
    else
    {
        [fileManager removeItemAtPath:_importUrl.path error:nil];
        _importUrl = nil;
    }
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
        _importUrl = nil;
}

- (void) processUrl:(NSURL *)url showAlwerts:(BOOL)showAlerts
{
    _importUrl = [url copy];
    
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
                [self doImport:NO];
            }
        }
        else
            [self doImport:NO];
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
}

-(void)processUrl:(NSURL*)url
{
    if ([url isFileURL])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self showProgressHUD];
            [self processUrl:url showAlwerts:YES];
            [self hideProgressAndRefresh];
        });
    }
}


- (void)commonInit
{
    _app = [OsmAndApp instance];
    _iapHelper = [OAIAPHelper sharedInstance];
    _savingHelper = [OASavingTrackHelper sharedInstance];
}

-(void)doImport:(BOOL)doRefresh
{
    if (_newGpxName) {
        [[NSFileManager defaultManager] moveItemAtPath:_importUrl.path toPath:[_app.gpxPath stringByAppendingPathComponent:_newGpxName] error:nil];
    } else {
        [[NSFileManager defaultManager] moveItemAtPath:_importUrl.path toPath:[_app.gpxPath stringByAppendingPathComponent:[_importUrl.path lastPathComponent]] error:nil];
    }
    
    OAGPXTrackAnalysis *analysis = [_doc getAnalysis:0];
    if (_newGpxName) {
        [[OAGPXDatabase sharedDb] addGpxItem:_newGpxName title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds analysis:analysis];
    } else {
        [[OAGPXDatabase sharedDb] addGpxItem:[_importUrl.path lastPathComponent] title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds analysis:analysis];
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
                    [enumerator skipDescendants];
                
                else if (![isDirectory boolValue] && [url.pathExtension isEqualToString:@"gpx"] && ![url.lastPathComponent isEqualToString:@"Favorites.gpx"])
                    [self processUrl:url showAlwerts:NO];

            }
        }
        [self hideProgressAndRefresh];
    });
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"menu_my_trips");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    
    [_segmentControl setTitle:OALocalizedString(@"menu_active_trips") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"menu_all_trips") forSegmentAtIndex:1];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    
    _editActive = NO;
    
    self.cancelButton.frame = self.backButton.frame;
    self.mapButton.frame = self.checkButton.frame;
    [self updateButtons];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

-(void)viewWillAppear:(BOOL)animated {
    
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

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _gpxTableView;
}

-(CGFloat) getToolBarHeight
{
    return self.tabBarController.tabBar.bounds.size.height;
}

-(CGFloat) getNavBarHeight
{
    return navBarWithSegmentControl;
}

-(void)viewWillDisappear:(BOOL)animated
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

- (void)onTrackRecordingChanged
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

- (void)onGpxRouteCanceled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_viewMode == kActiveTripsMode && _routeSectionIndex > -1)
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

-(void)generateData
{
    self.menuItems = [[NSArray alloc] init];
    
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    _visible = [OAAppSettings sharedManager].mapSettingVisibleGpx;
    
    if (_viewMode == kActiveTripsMode)
    {
        self.gpxList = [NSMutableArray array];
        for (OAGPX *item in db.gpxList)
        {
            if ([_visible containsObject:item.gpxFileName])
                [_gpxList addObject:item];
        }
    }
    else
    {
        self.gpxList = [NSMutableArray arrayWithArray:db.gpxList];
    }
    
    NSString *routeFileName = [[OAAppSettings sharedManager] mapSettingActiveRouteFileName];
    _isRouteActive = (routeFileName != nil);
    if (_isRouteActive)
    {
        _routeItem = [db getGPXItem:routeFileName];
        for (OAGPX *item in self.gpxList)
        {
            if ([item.gpxFileName isEqualToString:routeFileName])
            {
                [self.gpxList removeObject:item];
                break;
            }
        }
    }
    else
    {
        _routeItem = nil;
    }
    
    if (self.gpxList.count > 0)
    {
        // Sort items by date-time added desc
        NSArray *sortedArrayGroups = [self.gpxList sortedArrayUsingComparator:^NSComparisonResult(OAGPX* obj1, OAGPX* obj2) {
            return [obj2.importDate compare:obj1.importDate];
        }];
        [self.gpxList setArray:sortedArrayGroups];
    }
    
    // Generate menu items
    GpxTableGroup* itemData = [[GpxTableGroup alloc] init];
    itemData.groupName = OALocalizedString(@"import_export");
    itemData.type = kGPXCellTypeMenu;
    self.menuItems = @[@{@"text": OALocalizedString(@"gpx_import_title"),
                         @"icon": @"favorite_import_icon",
                         @"action": @"onImportClicked"}];
    itemData.groupItems = [[NSMutableArray alloc] initWithArray:self.menuItems];
    
    NSInteger index = 0;
    _recSectionIndex = (_viewMode == kActiveTripsMode ? index++ : -1);
    _routeSectionIndex = ((_viewMode == kActiveTripsMode && _isRouteActive) ? index++ : -1);
    _tripsSectionIndex = (self.gpxList.count > 0 ? index++ : -1);
    _createTripSectionIndex = (_viewMode == kActiveTripsMode ? index++ : -1);
    _menuSectionIndex = (_viewMode == kAllTripsMode ? index : -1);
}

-(void)setupView {
    
    [self.gpxTableView setDataSource:self];
    [self.gpxTableView setDelegate:self];
    self.gpxTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.gpxTableView reloadData];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)activeTripsClicked
{
    if (_viewMode == kAllTripsMode)
    {
        _viewMode = kActiveTripsMode;
        [self generateData];
        [_gpxTableView reloadData];
    }
}

- (void)allTripsClicked
{
    if (_viewMode == kActiveTripsMode)
    {
        _viewMode = kAllTripsMode;
        [self generateData];
        [_gpxTableView reloadData];
    }
}

- (IBAction)backButtonClicked:(id)sender
{
    [super backButtonClicked:sender];
}

- (IBAction)goRootScreen:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)updateRecButtonsAnimated
{
    [UIView animateWithDuration:.3 animations:^{
        if (_recCell)
        {
            [self updateRecImg];
            [self updateRecBtn];
        }
    }];
}

- (IBAction)mapButtonClick:(id)sender
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
    
    if (_viewMode == kActiveTripsMode && [OAAppSettings sharedManager].mapSettingShowRecordingTrack)
    {
        [self.gpxTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    
    [self.gpxTableView endUpdates];
    
    [self updateRecButtonsAnimated];
}

- (IBAction)checkButtonClick:(id)sender
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

    if (_viewMode == kActiveTripsMode)
    {
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
    }
    else
    {
        [settings updateGpx:gpxFilesNew];
    }
    
    NSInteger tripsSectionIndex = _tripsSectionIndex;
    
    _visible = [OAAppSettings sharedManager].mapSettingVisibleGpx;

    [self.gpxTableView setEditing:NO animated:YES];
    _editActive = NO;
    [self updateButtons];

    [self generateData];

    [self.gpxTableView beginUpdates];
    
    if (_viewMode == kAllTripsMode)
    {
        NSArray *visibleRows = [self.gpxTableView indexPathsForVisibleRows];
        [self.gpxTableView reloadRowsAtIndexPaths:visibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (indexes.count > 0)
    {
        if (self.gpxList.count == 0)
            [self.gpxTableView deleteSections:[NSIndexSet indexSetWithIndex:tripsSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        else
            [self.gpxTableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
    }
    
    [self.gpxTableView endUpdates];

    [self updateRecButtonsAnimated];
}

- (IBAction)cancelButtonClick:(id)sender
{
    [self.gpxTableView setEditing:NO animated:YES];
    _editActive = NO;
    [self updateButtons];
    [self updateRecButtonsAnimated];
}

- (IBAction)onSegmentChanged:(id)sender {
    switch (_segmentControl.selectedSegmentIndex)
    {
        case 0:
            return [self activeTripsClicked];
        case 1:
            return [self allTripsClicked];
    }
}

- (void)onImportClicked
{
//    NSString* favoritesImportText = OALocalizedString(@"gpx_import_desc");
//    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
//    [importHelpAlert show];
    OAImportGPXBottomSheetViewController *controller = [[OAImportGPXBottomSheetViewController alloc] initWithParam:self];
    [controller show];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (_viewMode)
    {
        case kActiveTripsMode:
            return 2 + (_isRouteActive ? 1 : 0) + (self.gpxList.count > 0 ? 1 : 0);
            
        case kAllTripsMode:
            return 1 + (self.gpxList.count > 0 ? 1 : 0);
            
        default:
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (_viewMode)
    {
        case kActiveTripsMode:
            if (section == _recSectionIndex)
                return OALocalizedString(@"record_trip");
            else if (section == _routeSectionIndex)
                return OALocalizedString(@"gpx_route");
            else if (section == _tripsSectionIndex)
                return OALocalizedString(@"tracks");
            else if (section == _createTripSectionIndex)
                return OALocalizedString(@"create_new_trip");
            
        case kAllTripsMode:
            if (section == _tripsSectionIndex)
                return nil;
            else if (section == _menuSectionIndex)
                return OALocalizedString(@"fav_import");
            
        default:
            break;
    }
    
    return nil;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (_viewMode)
    {
        case kActiveTripsMode:
            if (section == _recSectionIndex)
                return 1;
            else if (section == _routeSectionIndex)
                return 1;
            else if (section == _tripsSectionIndex)
                return [self.gpxList count];
            else if (section == _createTripSectionIndex)
                return 1;
            
        case kAllTripsMode:
            if (section == _tripsSectionIndex)
                return [self.gpxList count];
            else if (section == _menuSectionIndex)
                return [self.menuItems count];
            
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == _recSectionIndex)
    {
        if ([_iapHelper.trackRecording isActive])
        {
            if (!_recCell)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXRecCell" owner:self options:nil];
                _recCell = (OAGPXRecTableViewCell *)[nib objectAtIndex:0];
            }
            
            if (_recCell)
            {
                [_recCell.textView setText:OALocalizedString(@"track_recording_name")];
                
                _recCell.descriptionPointsView.text = [NSString stringWithFormat:@"%d %@", _savingHelper.points, [OALocalizedString(@"gpx_waypoints") lowercaseStringWithLocale:[NSLocale currentLocale]]];
                _recCell.descriptionDistanceView.text = [_app getFormattedDistance:_savingHelper.distance];
                
                [_recCell.btnStartStopRec addTarget:self action:@selector(startStopRecPressed) forControlEvents:UIControlEventTouchUpInside];
                [_recCell.btnSaveGpx addTarget:self action:@selector(saveGpxPressed) forControlEvents:UIControlEventTouchUpInside];
                
                [self updateRecImg];
                [self updateRecBtn];
            }
            
            return _recCell;
        }
        else
        {
            if (!_addonCell)
            {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.bounds.size.width, 44.0)];
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 0.0, tableView.bounds.size.width - 42.0, 44.0)];
                label.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
                label.numberOfLines = 2;
                label.textAlignment = NSTextAlignmentLeft;
                label.textColor = [UIColor darkGrayColor];
                label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                label.text = OALocalizedString(@"track_rec_addon_q");
                [cell addSubview:label];
                
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.bounds.size.width - 30.0, 12.5, 21.0, 21.0)];
                imageView.image = [UIImage imageNamed:@"menu_cell_pointer.png"];
                imageView.contentMode = UIViewContentModeCenter;
                imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
                [cell addSubview:imageView];
                
                _addonCell = cell;
            }
            
            return _addonCell;
        }
    }
    else if (indexPath.section == _routeSectionIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OAGPXRouteTableViewCell";
        
        OAGPXRouteTableViewCell* cell;
        cell = (OAGPXRouteTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXRouteCell" owner:self options:nil];
            cell = (OAGPXRouteTableViewCell *)[nib objectAtIndex:0];
            [cell.closeButton addTarget:self action:@selector(cancelRoutePressed) forControlEvents:UIControlEventTouchUpInside];
        }
        
        if (cell) {
            
            //[cell.iconView setImage: [UIImage imageNamed:@"icon_gpx_fill"]];
            
            [cell.titleView setText:[_routeItem getNiceTitle]];
            
            double distance = [OAGPXRouter sharedInstance].routeDoc.totalDistance;
            NSTimeInterval duration = [[OAGPXRouter sharedInstance] getRouteDuration];
            
            [cell setDistance:distance wptCount:_routeItem.wptPoints tripDuration:duration];
        }
        return cell;
    }
    else if (indexPath.section == _tripsSectionIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OAGPXTableViewCell";
        
        OAGPXTableViewCell* cell;
        cell = (OAGPXTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXCell" owner:self options:nil];
            cell = (OAGPXTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAGPX* item = [self.gpxList objectAtIndex:indexPath.row];
            [cell.textView setText:[item getNiceTitle]];
            [cell.descriptionDistanceView setText:[_app getFormattedDistance:item.totalDistance]];
            [cell.descriptionPointsView setText:[NSString stringWithFormat:@"%d %@", item.wptPoints, [OALocalizedString(@"gpx_waypoints") lowercaseStringWithLocale:[NSLocale currentLocale]]]];
            
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_pointer.png"]];
            
            if (_viewMode == kAllTripsMode && [_visible containsObject:item.gpxFileName])
                [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
            else
                [cell.iconView setImage:nil];
        }
        return cell;
    }
    else if (indexPath.section == _createTripSectionIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OAIconTextTableViewCell";
        
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText:OALocalizedString(@"create_new_trip")];
            [cell.iconView setImage: [UIImage imageNamed:@"icon_info"]];
        }
        return cell;
    }
    else
    {
        static NSString* const reusableIdentifierPoint = @"OAIconTextTableViewCell";
        
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
            [cell.textView setText:[item objectForKey:@"text"]];
            [cell.iconView setImage: [UIImage imageNamed:[item objectForKey:@"icon"]]];
        }
        return cell;
        
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self canEditRowAtIndexPath:indexPath];
}

-(BOOL)canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (_viewMode)
    {
        case kActiveTripsMode:
            if (indexPath.section == _createTripSectionIndex)
                return NO;
            else if (indexPath.section == _routeSectionIndex)
                return NO;
            else if (indexPath.section == _recSectionIndex && ![_iapHelper.trackRecording isActive])
                return NO;
            else
                return YES;
            
        case kAllTripsMode:
            if (indexPath.section == _tripsSectionIndex && self.gpxList.count > 0)
                return YES;
            else
                return NO;
            
        default:
            return NO;
            break;
    }
}

- (void)cancelRoutePressed
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

- (void)startStopRecPressed
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
        if (!settings.mapSettingSaveTrackIntervalApproved && ![_savingHelper hasData])
        {
            OATrackIntervalDialogView *view = [[OATrackIntervalDialogView alloc] initWithFrame:CGRectMake(0.0, 0.0, 252.0, 136.0)];
            
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
                                         settings.mapSettingSaveTrackIntervalGlobal = [settings.trackIntervalArray[[view getInterval]] intValue];
                                         if (view.swRemember.isOn)
                                             settings.mapSettingSaveTrackIntervalApproved = YES;

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

- (void)updateRecImg
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

- (void)doSaveTrack
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        else if (indexPath.section == _createTripSectionIndex)
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
        else
        {
            NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
            SEL action = NSSelectorFromString([item objectForKey:@"action"]);
            [self performSelector:action];
        }
    }
    
    if (![self.gpxTableView isEditing] || ![self canEditRowAtIndexPath:indexPath])
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
