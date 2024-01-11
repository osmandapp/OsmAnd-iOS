//
//  OAGPXListViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.12.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAGPXListViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAGpxInfo.h"
#import "OALoadGpxTask.h"
#import "OAGPXRecTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAGPXTrackCell.h"
#import "OAGPXDocument.h"
#import "OASavingTrackHelper.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAKml2Gpx.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OAAlertBottomSheetViewController.h"
#import "OARecordSettingsBottomSheetViewController.h"
#import "OAPluginsViewController.h"
#import "OARoutePlanningHudViewController.h"
#import <MBProgressHUD.h>
#import "OAExportItemsViewController.h"
#import "OAIndexConstants.h"
#import "OsmAndApp.h"
#import "OAOsmUploadGPXViewConroller.h"
#import "OAPointHeaderTableViewCell.h"
#import "OAGPXAppearanceCollection.h"
#import "OsmAnd_Maps-Swift.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/ArchiveReader.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define _(name) OAGPXListViewController__##name
#define kMaxCancelButtonWidth 100

#define GPX_EXT @"gpx"
#define KML_EXT @"kml"
#define KMZ_EXT @"kmz"

#define kImportFolderName @"import"
#define kactionsGrupId @"actionsGrup"

#define kRecordTrackRow 0
#define kRecordTrackSection 0
#define kGPXGroupHeaderRow 0
#define kVisibleTracksWithoutRoutePlanningSection 1
#define kRoutePlanningSection 1

@interface OAGpxTableGroup : NSObject
    @property NSString *type;
    @property BOOL isOpen;
    @property NSString *groupName;
    @property NSString *groupId;
    @property NSMutableArray *groupItems;
    @property NSString *groupIcon;
    @property BOOL isMenu;
    @property BOOL isSelectable;
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

@interface OAGPXListViewController () <UIDocumentPickerDelegate, UISearchResultsUpdating, UISearchBarDelegate>
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
    int _displayingTracksCount;
    NSInteger _actionsGroupIndex;
    
    CALayer *_horizontalLine;
    
    BOOL _editActive;
    NSArray<NSString *> *_visibleCurrentTracks;
    
    NSString *_importGpxPath;
    
    MBProgressHUD *_progressHUD;
    
    UIBarButtonItem *_selectAllButton;
    UIBarButtonItem *_doneButton;
    UIBarButtonItem *_selectionModeButton;
    UISearchController *_searchController;
    
    BOOL _isSearchActive;
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
    NSString *gpxFilePath = [_importUrl.path hasPrefix:_app.gpxPath]
            ? [OAUtilities getGpxShortPath:_importUrl.path]
            : [_importUrl.path lastPathComponent];
    [[OAGPXDatabase sharedDb] removeGpxItem:gpxFilePath];
}

- (void) setShouldPopToParent:(BOOL)shouldPop
{
    _popToParent = shouldPop;
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
                for (int i = 2; i < 100000; i++) {
                    newName = [[NSString stringWithFormat:@"%@_%d", [[_importUrl.path lastPathComponent] stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
                    if (![fileMan fileExistsAtPath:[_importGpxPath stringByAppendingPathComponent:newName]])
                        break;
                }
                
                _newGpxName = [newName copy];

                OAGPX *gpx = [self doImport:YES];
                if (openGpxView)
                {
                    [self doPush];
                    [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpx];
                }
            });
        };
        
        id overwriteHandler = ^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _newGpxName = nil;
                [self removeFromDB];

                OAGPX *gpx = [self doImport:YES];
                if (openGpxView)
                {
                    [self doPush];
                    [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpx];
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
                                                inController:self];
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
            NSString *gpxFilePath = [_importUrl.path stringByReplacingOccurrencesOfString:[_app.gpxPath stringByAppendingString:@"/"] withString:@""];
            if ([[OAGPXDatabase sharedDb] containsGPXItem:gpxFilePath])
            {
                [self showImportGpxAlert:OALocalizedString(@"import_tracks")
                                 message:OALocalizedString(@"gpx_import_already_exists_short")
                       cancelButtonTitle:OALocalizedString(@"shared_string_ok")
                       otherButtonTitles:@[]
                             openGpxView:openGpxView];
            }
            else if (showAlerts)
            {
                [self showImportGpxAlert:OALocalizedString(@"import_tracks")
                                 message:OALocalizedString(@"gpx_import_already_exists")
                       cancelButtonTitle:OALocalizedString(@"shared_string_cancel")
                       otherButtonTitles:@[OALocalizedString(@"gpx_add_new"), OALocalizedString(@"gpx_overwrite")]
                             openGpxView:openGpxView];
            }
            else
            {
                [[NSFileManager defaultManager] removeItemAtPath:[_importGpxPath stringByAppendingPathComponent:[_importUrl.path lastPathComponent]] error:nil];
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
            [[OARootViewController instance].mapPanel openTargetViewWithGPX:item];
        });
    }
}

- (void)prepareProcessUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView
{
    if ([url isFileURL])
    {
        [self prepareProcessUrl:^{
            [self processUrl:url showAlerts:showAlerts openGpxView:openGpxView];
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
    if (_newGpxName)
    {
        [fileManager copyItemAtPath:_importUrl.path toPath:[_importGpxPath stringByAppendingPathComponent:_newGpxName] error:nil];
    }
    else
    {
        [fileManager copyItemAtPath:_importUrl.path
                             toPath:[_importGpxPath stringByAppendingPathComponent:[self getCorrectedFilename:[_importUrl.path lastPathComponent]]]
                              error:nil];
    }

    if (_newGpxName)
    {
        NSString *storingPathInFolder = [kImportFolderName stringByAppendingPathComponent:_newGpxName];
        item = [[OAGPXDatabase sharedDb] addGpxItem:storingPathInFolder title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds document:_doc];
    }
    else
    {
        NSString *name = [self getCorrectedFilename:[_importUrl.path lastPathComponent]];
        NSString *storingPathInFolder = [kImportFolderName stringByAppendingPathComponent:name];
        item = [[OAGPXDatabase sharedDb] addGpxItem:storingPathInFolder title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds document:_doc];
    }
    [[OAGPXDatabase sharedDb] save];
    if (item.color != 0)
        [[OAGPXAppearanceCollection sharedInstance] getColorItemWithValue:item.color];

    [OAUtilities denyAccessToFile:_importUrl.path removeFromInbox:YES];

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
        UIView *topView = [UIApplication sharedApplication].mainWindow;
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

- (void) applyLocalization
{
    [self updateHeaderLabels];
}

- (void) updateHeaderLabels
{
    [_selectAllButton setTitle:OALocalizedString(@"shared_string_select_all")];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done")];
    
    if (_editActive)
    {
        if (_selectedItems.count > 0)
        {
            self.tabBarController.navigationItem.title = [NSString stringWithFormat:OALocalizedString(@"selected_tracks_count"), _selectedItems.count];
            if (_selectedItems.count == _displayingTracksCount)
                [_selectAllButton setTitle:OALocalizedString(@"shared_string_deselect_all")];
        }
        else
        {
            self.tabBarController.navigationItem.title = OALocalizedString(@"select_tracks");
        }
    }
    else
    {
        self.tabBarController.navigationItem.title = OALocalizedString(@"menu_my_trips");
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
    
    _editActive = NO;
    _isSearchActive = NO;

    [self setupView];
    
    _selectedIndexPaths = [[NSMutableArray alloc] init];
    _selectedItems = [[NSMutableArray alloc] init];
    _gpxFolders = [NSMutableDictionary dictionary];
    _visibleCurrentTracks = [NSArray arrayWithArray:[_settings.mapSettingVisibleGpx get]];
    
    _editToolbarView.hidden = YES;
    self.editToolbarView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    [self.editToolbarView.layer addSublayer:_horizontalLine];
    
    _exportButton.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    _showOnMapButton.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    _uploadToOSMButton.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    _deleteButton.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    [_exportButton setImage:[UIImage templateImageNamed:@"ic_custom_export.png"] forState:UIControlStateNormal];
    [_showOnMapButton setImage:[UIImage templateImageNamed:@"ic_custom_map_pin_outlined.png"] forState:UIControlStateNormal];
    [_uploadToOSMButton setImage:[UIImage templateImageNamed:@"ic_custom_upload_to_openstreetmap_outlined.png"] forState:UIControlStateNormal];
    [_deleteButton setImage:[UIImage templateImageNamed:@"ic_custom_remove.png"] forState:UIControlStateNormal];
    
    [self updateButtons];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    [self updateButtons];
    [self layoutBottomView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadData];
    
    _trackRecordingObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onTrackRecordingChanged)
                                                         andObserve:_app.trackRecordingObservable];
    [self applySafeAreaMargins];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewTracksFetched) name:kNotificationNewTracksFetched object:nil];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    _selectionModeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_overflow_menu_stroke.png"] style:UIBarButtonItemStylePlain target:self action:@selector(selectionModeButtonClick:)];
    _doneButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_done") style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonClick:)];
    _selectAllButton = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"shared_string_select_all") style:UIBarButtonItemStylePlain target:self action:@selector(selectAllButtonClick:)];
    [self.navigationController.navigationBar.topItem setRightBarButtonItems:@[_selectionModeButton] animated:YES];
    _selectionModeButton.accessibilityLabel = OALocalizedString(@"shared_string_menu");
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.tabBarController.navigationItem.searchController = _searchController;
    [self setupSearchController:NO filtered:NO];
    self.definesPresentationContext = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self updateHeaderLabels];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_trackRecordingObserver detach];
    _trackRecordingObserver = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationNewTracksFetched object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.definesPresentationContext = NO;
    
    if (![_visibleCurrentTracks isEqualToArray:[_settings.mapSettingVisibleGpx get]])
        [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
}

-(UIView *) getBottomView
{
    return _editActive ? _editToolbarView : nil;
}

-(CGFloat) getToolBarHeight
{
    return favoritesToolBarHeight;
}

- (void) updateButtons
{
    if (_editActive)
    {
        self.tabBarController.navigationItem.hidesBackButton = YES;
        [self.navigationController.navigationBar.topItem setLeftBarButtonItem:_selectAllButton animated:YES];
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_doneButton animated:YES];
    }
    else
    {
        self.tabBarController.navigationItem.hidesBackButton = NO;
        [self.navigationController.navigationBar.topItem setLeftBarButtonItem:nil];
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_selectionModeButton animated:YES];
    }
}

- (void) setupSearchController:(BOOL)isSearchActive filtered:(BOOL)isFiltered
{
    if (isSearchActive)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    else if (isFiltered)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorNamed:ACColorNameTextColorTertiary]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
    else
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _searchController.searchBar.searchTextField.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
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
    NSArray<NSString *> *visible = _settings.mapSettingVisibleGpx.get;
    self.gpxList = [NSMutableArray arrayWithArray:db.gpxList];
    _displayingTracksCount = 0;
    _actionsGroupIndex = -1;
    
    if (!_isSearchActive)
    {
        OAGpxTableGroup *trackRecordingGroup = [[OAGpxTableGroup alloc] init];
        trackRecordingGroup.isMenu = YES;
        trackRecordingGroup.type = [OASimpleTableViewCell getCellIdentifier];
        trackRecordingGroup.header = OALocalizedString(@"record_trip");
        
        if ([_iapHelper.trackRecording isActive])
            [trackRecordingGroup.groupItems addObject:@{
                @"title" : OALocalizedString(@"shared_string_currently_recording_track"),
                @"icon" : @"ic_custom_reverse_direction.png",
                @"type" : [OAGPXRecTableViewCell getCellIdentifier],
                @"key" : @"track_recording"}
            ];
        else
            [trackRecordingGroup.groupItems addObject:@{
                @"title" : OALocalizedString(@"track_rec_addon_q"),
                @"type" : [OASimpleTableViewCell getCellIdentifier],
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
            if ([visible containsObject:item.gpxFilePath])
            {
                [visibleGroup.groupItems addObject:
                 @{
                    @"title" : [item getNiceTitle],
                    @"icon" : @"ic_custom_trip",
                    @"track" : item,
                    @"type" : [OASwitchTableViewCell getCellIdentifier],
                    @"key" : @"track_group"}];
            }
        }
        visibleGroup.isOpen = YES;
        if (visibleGroup.groupItems.count > 0)
        {
            visibleGroup.groupItems = [visibleGroup.groupItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                NSString *title1 = obj1[@"title"];
                NSString *title2 = obj2[@"title"];
                return [title1.lowerCase compare: title2.lowerCase];
            }];
            [tableData addObject:visibleGroup];
        }
    }
    
    for (NSString *key in _gpxFolders.allKeys)
    {
        OAGpxTableGroup* tracksGroup = [[OAGpxTableGroup alloc] init];
        tracksGroup.groupName = [OAUtilities capitalizeFirstLetter:OALocalizedString(key)];
        tracksGroup.groupIcon = @"ic_custom_folder";
        tracksGroup.isMenu = NO;
        tracksGroup.isSelectable = YES;
        tracksGroup.type = kGPXGroupHeaderRow;
        tracksGroup.header = @"";
        for (OAGpxInfo *track in _gpxFolders[key])
        {
            if (!track.gpx)
                continue;
            
            [tracksGroup.groupItems addObject:@{
                @"type" : [OAGPXTrackCell getCellIdentifier],
                @"title" : [track.file stringByDeletingPathExtension],
                @"track" : track.gpx,
                @"distance" : [OAOsmAndFormatter getFormattedDistance:track.gpx.totalDistance],
                @"time" : [OAOsmAndFormatter getFormattedTimeInterval:track.gpx.timeSpan shortFormat:YES],
                @"importDate" : track.gpx.importDate,
                @"wpt" : [NSString stringWithFormat:@"%d", track.gpx.wptPoints],
                @"key" : @"track_group"
            }];
            _displayingTracksCount++;
        }
        tracksGroup.isOpen = NO;
        if (tracksGroup.groupItems.count > 0)
        {
            if ([key isEqualToString:@"import"])
            {
                tracksGroup.groupItems = [tracksGroup.groupItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                    NSDate *importDate1 = obj1[@"importDate"];
                    NSDate *importDate2 = obj2[@"importDate"];
                    return [importDate2 compare: importDate1];
                }];
            }
            else
            {
                tracksGroup.groupItems = [tracksGroup.groupItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                    NSString *title1 = obj1[@"title"];
                    NSString *title2 = obj2[@"title"];
                    return [title1.lowerCase compare: title2.lowerCase];
                }];
            }
            [tableData addObject:tracksGroup];
        }
    }
    if (!_isSearchActive && !_editActive)
    {
        [self addActionsGrup:tableData];
    }
    _data = [NSMutableArray arrayWithArray:tableData];
}

-(void) addActionsGrup:(NSMutableArray *)tableData
{
    // Generate menu items
    OAGpxTableGroup* actionsGroup = [[OAGpxTableGroup alloc] init];
    actionsGroup.isMenu = YES;
    actionsGroup.groupId = kactionsGrupId;
    actionsGroup.type = [OASimpleTableViewCell getCellIdentifier];
    actionsGroup.header = OALocalizedString(@"shared_string_actions");
    self.menuItems = @[@{@"type" : [OASimpleTableViewCell getCellIdentifier],
                         @"key" : @"import_track",
                         @"title": OALocalizedString(@"import_tracks"),
                         @"icon": @"ic_custom_import",
                         @"header" : OALocalizedString(@"shared_string_actions")},
                       @{@"type" : [OASimpleTableViewCell getCellIdentifier],
                         @"key" : @"create_new_trip",
                         @"title": OALocalizedString(@"create_new_trip"),
                         @"icon": @"ic_custom_trip.png"}];
    actionsGroup.groupItems = [NSMutableArray arrayWithArray:self.menuItems];
    
    [tableData addObject:actionsGroup];
    _actionsGroupIndex = tableData.count - 1;
}

-(void) updateData
{
    NSMutableArray *mutableDataCopy = [NSMutableArray arrayWithArray:_data];
    OAGpxTableGroup* groupActions = nil;
    
    for (OAGpxTableGroup *group in mutableDataCopy)
    {
        if ([group.groupId isEqualToString:kactionsGrupId])
        {
            groupActions = group;
            break;
        }
    }
    
    if (!_isSearchActive)
        [self manageGroup:groupActions inData:mutableDataCopy];
    
    _data = mutableDataCopy;
}

-(void) manageGroup:(OAGpxTableGroup *)groupActions inData:(NSMutableArray *)data
{
    if (groupActions && _editActive)
    {
        [data removeObject:groupActions];
        _actionsGroupIndex = -1;
    }
    else if (!groupActions && !_editActive)
    {
        [self addActionsGrup:data];
    }
}

-(void) setupView
{
    [self.gpxTableView setDataSource:self];
    [self.gpxTableView setDelegate:self];
    self.gpxTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.gpxTableView reloadData];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction) goRootScreen:(id)sender
{
    if (_popToParent)
    {
        [super onLeftNavbarButtonPressed];
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

- (void) layoutBottomView
{
    if (_editActive)
    {
        self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
    }
    else
    {
        self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight - self.tabBarController.tabBar.frame.size.height, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
        _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    }
    [self applySafeAreaMargins];
}

- (IBAction) selectionModeButtonClick:(id)sender
{
    _editActive = YES;
    _editToolbarView.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        [self layoutBottomView];
    } completion:^(BOOL finished) {
        [self.tabBarController.tabBar setHidden:YES];
    }];
    
    [self.gpxTableView setEditing:YES animated:YES];
    [self updateData];
    if (_actionsGroupIndex != -1)
        [self.gpxTableView deleteSections:[NSIndexSet indexSetWithIndex:_actionsGroupIndex] withRowAnimation:UITableViewRowAnimationFade];
    [self.gpxTableView reloadData];
    [self updateHeaderLabels];
    [self updateButtons];
    [self updateRecButtonsAnimated];
}

- (IBAction) doneButtonClick:(id)sender
{
    _editActive = NO;
    [UIView animateWithDuration:.3 animations:^{
        [self.tabBarController.tabBar setHidden:NO];
        [self layoutBottomView];
    } completion:^(BOOL finished) {
        _editToolbarView.hidden = YES;
    }];
    
    [self.gpxTableView setEditing:NO animated:YES];
    [_selectedItems removeAllObjects];
    [_selectedIndexPaths removeAllObjects];
    [self updateData];
    if (_actionsGroupIndex != -1)
        [self.gpxTableView insertSections:[NSIndexSet indexSetWithIndex:_actionsGroupIndex] withRowAnimation:UITableViewRowAnimationFade];
    [self updateHeaderLabels];
    [self updateButtons];
    [self updateRecButtonsAnimated];
}

- (IBAction) selectAllButtonClick:(id)sender
{
    BOOL shouldDeselect = _selectedItems.count == _displayingTracksCount;
    if (!shouldDeselect)
    {
        [_selectedItems removeAllObjects];
        [_selectedIndexPaths removeAllObjects];
    }
    
    for (int i = 0; i < _data.count; i++)
    {
        OAGpxTableGroup *group = _data[i];
        if (group.isSelectable)
        {
            if (shouldDeselect)
                [self deselectAllGroup:i];
            else
                [self selectAllGroup:i];
        }
    }
    [self updateHeaderLabels];
}

- (void) onImportClicked
{
    NSArray<UTType *> *contentTypes = @[[UTType importedTypeWithIdentifier:@"com.topografix.gpx" conformingToType:UTTypeXML],
                                        [UTType importedTypeWithIdentifier:@"com.google.earth.kmz" conformingToType:UTTypeXML],
                                        [UTType importedTypeWithIdentifier:@"com.google.earth.kml" conformingToType:UTTypeXML]];
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:YES];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
    
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
            OARecordSettingsBottomSheetViewController *bottomSheet = [[OARecordSettingsBottomSheetViewController alloc] initWithCompletitionBlock:^(int recordingInterval, BOOL rememberChoice, BOOL showOnMap) {
                
                
                [_settings.mapSettingSaveTrackIntervalGlobal set:[_settings.trackIntervalArray[recordingInterval] intValue]];
                if (rememberChoice)
                    [_settings.mapSettingSaveTrackIntervalApproved set:YES];

                [_settings.mapSettingShowRecordingTrack set:showOnMap];

                _settings.mapSettingTrackRecording = YES;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateRecImg];
                });
            }];
            
            [bottomSheet presentInViewController:OARootViewController.instance];
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
        _recCell.btnStartStopRec.tintColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    }
    else
    {
        [_recCell.btnStartStopRec setImage:[UIImage imageNamed:@"ic_action_rec_start.png"] forState:UIControlStateNormal];
        _recCell.btnStartStopRec.tintColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
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
        [OAAlertBottomSheetViewController showAlertWithTitle:nil
                                                   titleIcon:nil
                                                     message:OALocalizedString(@"track_save_short_q")
                                                 cancelTitle:OALocalizedString(@"shared_string_no")
                                                   doneTitle:OALocalizedString(@"shared_string_yes")
                                            doneColpletition:^{
                                                [self doSaveTrack];
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
        [OAAlertBottomSheetViewController showAlertWithTitle:nil
                                                   titleIcon:nil
                                                     message:OALocalizedString(@"track_continue_rec_q")
                                                 cancelTitle:OALocalizedString(@"shared_string_no")
                                                   doneTitle:OALocalizedString(@"shared_string_yes")
                                            doneColpletition:^{
                                                _settings.mapSettingTrackRecording = YES;
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self updateRecImg];
                                                });
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

- (IBAction) exportButtonClicked:(id)sender
{
    if (_selectedItems.count > 0)
    {
        NSMutableArray<NSString *> *paths = [NSMutableArray array];
        for (OAGPX *gpx in _selectedItems)
            [paths addObject:gpx.absolutePath];
        
        OAExportItemsViewController *exportController = [[OAExportItemsViewController alloc] initWithTracks:[NSArray arrayWithArray:paths]];
        [self.navigationController pushViewController:exportController animated:YES];
        [self doneButtonClick:nil];
    }
}

- (IBAction) showOnMapButtonClicked:(id)sender
{
    if (_selectedItems.count > 0)
    {
        NSMutableArray<OAGPX *> *gpxArrHide = [NSMutableArray arrayWithArray:self.gpxList];
        NSMutableArray<OAGPX *> *gpxArrNew = [NSMutableArray array];
        NSMutableArray<NSString *> *gpxFilesHide = [NSMutableArray array];
        NSMutableArray<NSString *> *gpxFilesNew = [NSMutableArray array];
        
        for (OAGPX *gpx in _selectedItems)
        {
            [gpxArrHide removeObject:gpx];
            [gpxArrNew addObject:gpx];
        }
        for (OAGPX *gpx in gpxArrHide)
            [gpxFilesHide addObject:gpx.gpxFilePath];
        for (OAGPX *gpx in gpxArrNew)
            [gpxFilesNew addObject:gpx.gpxFilePath];
        
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
        _actionsGroupIndex = -1;
        [self.gpxTableView reloadData];
        
        [self doneButtonClick:nil];
    }
}

- (IBAction) deleteButtonClicked:(id)sender
{
    if (_selectedItems.count > 0)
    {
        OAGPXListDeletingBottomSheetViewController *bottomSheet = [[OAGPXListDeletingBottomSheetViewController alloc] init];
        bottomSheet.deletingTracksCount = _selectedItems.count;
        bottomSheet.delegate = self;
        [bottomSheet presentInViewController:self];
    }
}

- (IBAction) uploadToOSMButtonClicked:(id)sender
{
    if (_selectedItems.count > 0)
    {
        OAOsmUploadGPXViewConroller *vc = [[OAOsmUploadGPXViewConroller alloc] initWithGPXItems:_selectedItems];
        [self.navigationController pushViewController:vc animated:YES];
    }
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
    else if (_isSearchActive)
        return 0.;
    else
        return 24.;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OAGpxTableGroup* groupData = [_data objectAtIndex:section];
    if (groupData.isMenu || _isSearchActive)
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
                [_recCell.textView setText:OALocalizedString(@"shared_string_currently_recording_track")];
                
                _recCell.descriptionPointsView.text = [NSString stringWithFormat:@"%d %@", _savingHelper.points, [OALocalizedString(@"shared_string_waypoints") lowercaseStringWithLocale:[NSLocale currentLocale]]];
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
        else if ([menuCellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
        {
            OASimpleTableViewCell *cell = (OASimpleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
            BOOL isImportCreateTrack = [menuItem[@"key"] isEqualToString:@"import_track"] || [menuItem[@"key"] isEqualToString:@"create_new_trip"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OASimpleTableViewCell *) nib[0];
                [cell descriptionVisibility:NO];
            }
            if (cell)
            {
                [cell leftIconVisibility:isImportCreateTrack];
                
                if (isImportCreateTrack)
                {
                    cell.titleLabel.text = menuItem[@"title"];
                    cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17.0];
                    cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                    cell.leftIconView.image = [UIImage templateImageNamed:menuItem[@"icon"]];
                    cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                }
                else
                {
                    cell.leftIconView.image = nil;
                    cell.titleLabel.text = OALocalizedString(@"track_rec_addon_q");
                    cell.titleLabel.font = [UIFont scaledSystemFontOfSize:14.0];
                    cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
                }
            }
            return cell;
        }
    }
    else
    {
        if (indexPath.row == kGPXGroupHeaderRow && !_isSearchActive)
        {
            OAPointHeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAPointHeaderTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointHeaderTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OAPointHeaderTableViewCell *) nib[0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.folderIcon.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
                cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
                cell.arrowImage.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
            }
            if (cell)
            {
                cell.groupTitle.text = item.groupName;
                cell.folderIcon.image = [UIImage templateImageNamed:item.groupIcon];
                cell.valueLabel.text = [NSString stringWithFormat:@"%ld", item.groupItems.count];
                
                cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
                [cell.openCloseGroupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                
                if ([self.gpxTableView isEditing])
                    [cell.openCloseGroupButton setHidden:NO];
                else
                    [cell.openCloseGroupButton setHidden:YES];
                
                if (item.isOpen)
                    cell.arrowImage.image = [UIImage templateImageNamed:@"ic_custom_arrow_down"];
                else
                    cell.arrowImage.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            }
            return cell;
        }
        else
        {
            NSInteger dataIndex = _isSearchActive ? indexPath.row : indexPath.row - 1;
            NSDictionary *groupItem = item.groupItems[dataIndex];
            NSString *cellType = groupItem[@"type"];
            OAGPX *gpx = groupItem[@"track"];
            if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
            {
                OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
                    cell = (OASwitchTableViewCell *) nib[0];
                    [cell descriptionVisibility:NO];
                    cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                }
                if (cell)
                {
                    cell.titleLabel.text = groupItem[@"title"];
                    cell.leftIconView.image = [UIImage templateImageNamed:groupItem[@"icon"]];
                    cell.leftIconView.tintColor = [_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath] ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];

                    [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    cell.switchView.on = [_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath];
                    [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
                    cell.switchView.tag = indexPath.section << 10 | indexPath.row;
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
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
                    [cell setRightButtonVisibility:!_editActive];
                    [cell.editButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_right"] forState:UIControlStateNormal];
                    cell.editButton.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
                    cell.leftIconImageView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
                    cell.leftIconImageView.tintColor = [_settings.mapSettingVisibleGpx.get containsObject:gpx.gpxFilePath] ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
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
        return NO;
    }
    else
        return YES;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *vw = (UITableViewHeaderFooterView *) view;
    [vw.textLabel setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
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
    
    [self updateHeaderLabels];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGpxTableGroup *item = [_data objectAtIndex:indexPath.section];
    if (![self.gpxTableView isEditing])
    {
        if (item.isMenu)
        {
            [self didSelectGpxTableGroupItem:item indexPath:indexPath];
        }
        else if (indexPath.row == 0 && !_isSearchActive)
        {
            [self openCloseGroup:indexPath];
        }
        else
        {
            NSDictionary *gpxInfo = _isSearchActive ? item.groupItems[indexPath.row] : item.groupItems[indexPath.row - 1];
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
        else if (indexPath.row == kGPXGroupHeaderRow)
            [self selectAllGroup:indexPath.section];
        else
            [self selectDeselectGroupItem:indexPath select:YES];
    }
    [self updateHeaderLabels];
}

- (void)didSelectGpxTableGroupItem:(OAGpxTableGroup *)item indexPath:(NSIndexPath *)indexPath
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
    for (; section < [self.gpxTableView numberOfSections]; section++)
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

#pragma mark - OAGPXListDeletingBottomSheetDelegate

- (void)onDeleteConfirmed {
    for (OAGPX *gpx in _selectedItems)
    {
        [_settings hideGpx:@[gpx.gpxFilePath] update:YES];
        [[OAGPXDatabase sharedDb] removeGpxItem:gpx.gpxFilePath];
    }
    [self reloadData];
}

// MARK: UIDocumentPickerDelegate

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
        [self reloadData];
    }
}

// MARK: NewTracksFetched Notification

- (void) onNewTracksFetched
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

// MARK: Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBounds;
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.gpxTableView contentInset];
        [self.gpxTableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardBounds.size.height, insets.right)];
        [self.gpxTableView setScrollIndicatorInsets:self.gpxTableView.contentInset];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.gpxTableView contentInset];
        [self.gpxTableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0.0, insets.right)];
        [self.gpxTableView setScrollIndicatorInsets:self.gpxTableView.contentInset];
    } completion:nil];
}

// MARK: UISearchResultsUpdating

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (searchController.isActive && searchController.searchBar.searchTextField.text.length == 0)
    {
        _isSearchActive = YES;
        [self setupSearchController:YES filtered:NO];
        [self generateData];
        [self.gpxTableView reloadData];
    }
    else if (searchController.isActive && searchController.searchBar.searchTextField.text.length > 0)
    {
        [self setupSearchController:NO filtered:YES];
        NSMutableArray *filteredItems = [NSMutableArray array];
        
        for (NSString *key in _gpxFolders.allKeys)
        {
            OAGpxTableGroup *tracksGroup = [[OAGpxTableGroup alloc] init];
            for (OAGpxInfo *track in _gpxFolders[key])
            {
                if (!track.gpx)
                    continue;
                
                NSRange nameTagRange = [[track getName] rangeOfString:searchController.searchBar.searchTextField.text options:NSCaseInsensitiveSearch];
                if (nameTagRange.location != NSNotFound)
                {
                    [tracksGroup.groupItems addObject:@{
                        @"type" : [OAGPXTrackCell getCellIdentifier],
                        @"title" : [track getName],
                        @"track" : track.gpx,
                        @"distance" : [OAOsmAndFormatter getFormattedDistance:track.gpx.totalDistance],
                        @"time" : [OAOsmAndFormatter getFormattedTimeInterval:track.gpx.timeSpan shortFormat:YES],
                        @"importDate" : track.gpx.importDate,
                        @"wpt" : [NSString stringWithFormat:@"%d", track.gpx.wptPoints],
                        @"key" : @"track_group"
                    }];
                }
            }
            tracksGroup.isOpen = NO;
            if (tracksGroup.groupItems.count > 0)
            {
                if ([key isEqualToString:@"import"])
                {
                    tracksGroup.groupItems = [tracksGroup.groupItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                        NSDate *importDate1 = obj1[@"importDate"];
                        NSDate *importDate2 = obj2[@"importDate"];
                        return [importDate2 compare: importDate1];
                    }];
                }
                else
                {
                    tracksGroup.groupItems = [tracksGroup.groupItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
                        NSString *title1 = obj1[@"title"];
                        NSString *title2 = obj2[@"title"];
                        return [title1.lowerCase compare: title2.lowerCase];
                    }];
                }
                [filteredItems addObject:tracksGroup];
            }
        }
        _data = [NSMutableArray arrayWithArray:filteredItems];
        [self.gpxTableView reloadData];
    }
    else
    {
        _isSearchActive = NO;
        [self setupSearchController:NO filtered:NO];
        [self generateData];
        [self.gpxTableView reloadData];
    }
}

// MARK: UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
    searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
}

@end
