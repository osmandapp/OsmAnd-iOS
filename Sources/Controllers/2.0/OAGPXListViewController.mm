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
#import "OAGPXTrackAnalysis.h"
#import "OASavingTrackHelper.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"
#import "OAUtilities.h"
#import "PXAlertView.h"
#import "OAPurchasesViewController.h"

#import "OATrackIntervalDialogView.h"


#define _(name) OAGPXListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4

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

    OsmAndAppInstance _app;
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
    OAGPXRecTableViewCell* _recCell;
    UITableViewCell *_addonCell;
    OAAutoObserverProxy* _trackRecordingObserver;
    OASavingTrackHelper *_savingHelper;

    NSInteger _recSectionIndex;
    NSInteger _tripsSectionIndex;
    NSInteger _menuSectionIndex;
    
    CALayer *_horizontalLine;
    
    BOOL _editActive;
    NSArray *_visible;
}

static OAGPXListViewController *parentController;

+ (BOOL)popToParent
{
    if (!parentController)
        return NO;
    
    [OAGPXListViewController doPop];
    
    return YES;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _viewMode = kActiveTripsMode;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithActiveTrips;
{
    self = [super init];
    if (self)
    {
        _viewMode = kActiveTripsMode;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithAllTrips;
{
    self = [super init];
    if (self)
    {
        _viewMode = kAllTripsMode;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithImportGPXItem:(NSURL*)url
{
    _viewMode = kAllTripsMode;

    [self commonInit];
    
    // Try to process gpx
    if ([url isFileURL])
    {
        _importUrl = [url copy];

        // Try to import gpx
        BOOL exists = [[OAGPXDatabase sharedDb] containsGPXItem:[_importUrl.path lastPathComponent]];
        
        _doc = [[OAGPXDocument alloc] initWithGpxFile:_importUrl.path];
        if (_doc) {
            
            if (exists) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"gpx_import_title") message:OALocalizedString(@"gpx_import_already_exists") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles:OALocalizedString(@"gpx_add_new"), OALocalizedString(@"gpx_overwrite"), nil];
                [alert show];
                
            } else {
                
                [self doImport:NO];
            }
            
        } else {

            _doc = nil;
            _importUrl = nil;

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"gpx_import_title") message:OALocalizedString(@"gpx_cannot_import") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil, nil];
            [alert show];
            
        }
        

        self = [super init];
        if (self) {

        }
        
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
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

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex != alertView.cancelButtonIndex) {
        
        if (buttonIndex == 1) {

            dispatch_async(dispatch_get_main_queue(), ^{
                NSFileManager *fileMan = [NSFileManager defaultManager];
                NSString *ext = [_importUrl.path pathExtension];
                NSString *newName;
                for (int i = 1; i < 100000; i++) {
                    newName = [[NSString stringWithFormat:@"%@_%d", [[_importUrl.path lastPathComponent] stringByDeletingPathExtension], i] stringByAppendingPathExtension:ext];
                    if (![fileMan fileExistsAtPath:[_app.gpxPath stringByAppendingPathComponent:newName]])
                        break;
                }
                
                _newGpxName = [newName copy];
            
                [self doImport:YES];
            });

        } else {
        
            dispatch_async(dispatch_get_main_queue(), ^{
                _newGpxName = nil;
                [[OAGPXDatabase sharedDb] removeGpxItem:[_importUrl.path lastPathComponent]];
                [[OAGPXDatabase sharedDb] save];
                [self doImport:YES];
            });
        }
        
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:_importUrl.path error:nil];
    }
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"menu_my_trips");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    
    [_activeTripsButtonView setTitle:OALocalizedStringUp(@"menu_active_trips") forState:UIControlStateNormal];
    [_allTripsButtonView setTitle:OALocalizedStringUp(@"menu_all_trips") forState:UIControlStateNormal];

    if (_viewMode == kActiveTripsMode)
    {
        [_activeTripsButtonView setImage:[UIImage imageNamed:@"ic_tabbar_active_trip_selected"] forState:UIControlStateNormal];
        [_allTripsButtonView setImage:[UIImage imageNamed:@"icon_gpx"] forState:UIControlStateNormal];
        
        [_activeTripsButtonView setTitleColor:UIColorFromRGB(0xffb300) forState:UIControlStateNormal];
        [_allTripsButtonView setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
    }
    else
    {
        [_activeTripsButtonView setImage:[UIImage imageNamed:@"ic_tabbar_active_trip_normal"] forState:UIControlStateNormal];
        [_allTripsButtonView setImage:[UIImage imageNamed:@"icon_gpx_fill"] forState:UIControlStateNormal];
        
        [_activeTripsButtonView setTitleColor:UIColorFromRGB(0xc8c8c8) forState:UIControlStateNormal];
        [_allTripsButtonView setTitleColor:UIColorFromRGB(0xffb300) forState:UIControlStateNormal];
    }

    [OAUtilities layoutComplexButton:self.activeTripsButtonView];
    [OAUtilities layoutComplexButton:self.allTripsButtonView];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    [self.toolbarView.layer addSublayer:_horizontalLine];
    
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
}

-(void)viewWillDisappear:(BOOL)animated
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
    if (_editActive)
        [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    else
        [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
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
    
    
    _recSectionIndex = (_viewMode == kActiveTripsMode ? 0 : -1);
    _tripsSectionIndex = (self.gpxList.count > 0 ? (_viewMode == kActiveTripsMode ? 1 : 0) : -1);
    _menuSectionIndex = (_viewMode == kAllTripsMode ? _tripsSectionIndex + 1 : -1);
    
    [self.gpxTableView reloadData];
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

- (IBAction)activeTripsClicked:(id)sender
{
    if (_viewMode == kAllTripsMode)
    {
        OAGPXListViewController* viewController = [[OAGPXListViewController alloc] initWithActiveTrips];
        [self.navigationController pushViewController:viewController animated:NO];
    }
}

- (IBAction)allTripsClicked:(id)sender
{
    if (_viewMode == kActiveTripsMode)
    {
        OAGPXListViewController* viewController = [[OAGPXListViewController alloc] initWithAllTrips];
        [self.navigationController pushViewController:viewController animated:NO];
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

- (IBAction)mapButtonClick:(id)sender
{
    [self.gpxTableView setEditing:YES animated:YES];
    _editActive = YES;
    [self updateButtons];
}

- (IBAction)checkButtonClick:(id)sender
{
    NSArray *selectedRows = [self.gpxTableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
    {
        [self.gpxTableView setEditing:NO animated:YES];
        _editActive = NO;
        [self updateButtons];
        return;
    }

    OAAppSettings *settings = [OAAppSettings sharedManager];
    
    for (NSIndexPath *indexPath in selectedRows)
    {
        OAGPX* gpx = [self.gpxList objectAtIndex:indexPath.row];
        if (_viewMode == kActiveTripsMode)
            [settings hideGpx:gpx.gpxFileName];
        else
            [settings showGpx:gpx.gpxFileName];
    }

    [[_app updateGpxTracksOnMapObservable] notifyEvent];

    [self.gpxTableView setEditing:NO animated:YES];
    _editActive = NO;
    [self updateButtons];

    [self generateData];
}

- (IBAction)cancelButtonClick:(id)sender
{
    [self.gpxTableView setEditing:NO animated:YES];
    _editActive = NO;
    [self updateButtons];
}

- (void)onImportClicked
{
    NSString* favoritesImportText = OALocalizedString(@"gpx_import_desc");
    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
    [importHelpAlert show];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    switch (_viewMode)
    {
        case kActiveTripsMode:
            return 1 + (self.gpxList.count > 0 ? 1 : 0);
            
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
            if (section == 0)
                return OALocalizedString(@"record_trip");
            else
                return OALocalizedString(@"tracks");
            
        case kAllTripsMode:
            if (section == 0 && self.gpxList.count > 0)
                return nil;
            else
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
            if (section == 0)
                return 1;
            else if (self.gpxList.count > 0)
                return [self.gpxList count];
            
        case kAllTripsMode:
            if (section == 0 && self.gpxList.count > 0)
                return [self.gpxList count];
            else
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
        if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
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
                
                _recCell.selectionStyle = ([_savingHelper hasData] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);
                
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
    switch (_viewMode)
    {
        case kActiveTripsMode:
            if (indexPath.section == 0)
                return NO;
            else if (self.gpxList.count > 0)
                return YES;
            
        case kAllTripsMode:
            if (indexPath.section == 0 && self.gpxList.count > 0)
                return YES;
            else
                return NO;
            
        default:
            return NO;
            break;
    }
}

- (void)startStopRecPressed
{
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
            OATrackIntervalDialogView *view = [[OATrackIntervalDialogView alloc] initWithFrame:CGRectMake(0.0, 0.0, 252.0, 116.0)];
            
            [PXAlertView showAlertWithTitle:OALocalizedString(@"track_start_rec")
                                    message:nil
                                cancelTitle:OALocalizedString(@"shared_string_cancel")
                                 otherTitle:OALocalizedString(@"shared_string_ok")
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
    
}

- (void)updateRecBtn
{
    _recCell.btnSaveGpx.enabled = [_savingHelper hasData];
}

- (void)saveGpxPressed
{
    if ([_savingHelper hasDataToSave] && _savingHelper.distance < 10.0)
    {
        [PXAlertView showAlertWithTitle:OALocalizedString(@"track_save_short_q")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_no")
                             otherTitle:OALocalizedString(@"shared_string_yes")
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
    if ([self.gpxTableView isEditing])
        return;
    
    if (indexPath.section == _recSectionIndex)
    {
        if ([[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
        {
            if ([_savingHelper hasData])
            {
                [self doPush];
                [[OARootViewController instance].mapPanel openTargetViewWithGPX:nil pushed:YES];
            }
        }
        else
        {
            OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
            purchasesViewController.openFromCustomPlace = YES;
            [self.navigationController pushViewController:purchasesViewController animated:YES];
        }
    }
    else if (indexPath.section == _tripsSectionIndex)
    {
        OAGPX* item = [self.gpxList objectAtIndex:indexPath.row];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithGPX:item pushed:YES];
    }
    else
    {
        NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)doPush
{    
    parentController = self;
    
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
