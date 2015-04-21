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
#import "OAFavoriteListViewController.h"
#import "OAMapViewController.h"

#import "OAGPXTableViewCell.h"

#import "OsmAndApp.h"
#import "OsmAndCore/GpxDocument.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"
#import "OAGPXTrackAnalysis.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


#define _(name) OAGPXListViewController__##name
#define kAlertViewRemoveId -3
#define kAlertViewShareId -4


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


@interface OAGPXListViewController () {
    OsmAndAppInstance _app;
    NSURL *_importUrl;
    OAGPXDocument *_doc;
    NSString *_newGpxName;

    BOOL _isExport;
    NSInteger _selectedIndex;
}

@property (strong, nonatomic) NSMutableArray* gpxList;
@property (strong, nonatomic) NSArray* menuItems;
@property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OAGPXListViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (instancetype)initExport
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _isExport = YES;
        _selectedIndex = -1;
    }
    return self;
}

- (instancetype)initWithImportGPXItem:(NSURL*)url
{
    _app = [OsmAndApp instance];
    
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
    _titleView.text = OALocalizedString(@"tracks");
    [_exportButton setTitle:OALocalizedString(@"gpx_export") forState:UIControlStateNormal];
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_favoritesButtonView setTitle:OALocalizedStringUp(@"favorites") forState:UIControlStateNormal];
    [_gpxButtonView setTitle:OALocalizedStringUp(@"tracks") forState:UIControlStateNormal];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_isExport) {

        [self.backButton removeTarget:self action:@selector(goRootScreen:) forControlEvents:UIControlEventTouchUpInside];
        [self.backButton addTarget:self action:@selector(backButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        self.exportButton.hidden = NO;
        
    } else {
        
        self.exportButton.hidden = YES;
    }
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self generateData];
    [self setupView];
}

-(void)generateData {
    
    self.menuItems = [[NSArray alloc] init];
    
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    self.gpxList = [NSMutableArray arrayWithArray:db.gpxList];
    
    
    // Sort items by date-time added desc
    NSArray *sortedArrayGroups = [self.gpxList sortedArrayUsingComparator:^NSComparisonResult(OAGPX* obj1, OAGPX* obj2) {
        return [obj2.importDate compare:obj1.importDate];
    }];
    [self.gpxList setArray:sortedArrayGroups];
    
    
    // Generate menu items
    GpxTableGroup* itemData = [[GpxTableGroup alloc] init];
    itemData.groupName = OALocalizedString(@"gpx_import_export");
    itemData.type = kGPXCellTypeMenu;
    self.menuItems = @[@{@"text": OALocalizedString(@"gpx_import_title"),
                         @"icon": @"favorite_import_icon",
                         @"action": @"onImportClicked"},
                       @{@"text": OALocalizedString(@"gpx_export_title"),
                         @"icon": @"favorite_export_icon.png",
                         @"action": @"onExportClicked"}];
    itemData.groupItems = [[NSMutableArray alloc] initWithArray:self.menuItems];
    
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

- (IBAction)exportClicked:(id)sender
{
    if (_selectedIndex  < 0) {
        
        UIAlertView* exportHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"gpx_export_select_track") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [exportHelpAlert show];
        
    } else {

        OAGPX* item = [self.gpxList objectAtIndex:_selectedIndex];

        NSURL* gpxUrl = [NSURL fileURLWithPath:[_app.gpxPath stringByAppendingPathComponent:item.gpxFileName]];
        _exportController = [UIDocumentInteractionController interactionControllerWithURL:gpxUrl];
        _exportController.UTI = @"net.osmand.gpx";
        _exportController.delegate = self;
        _exportController.name = item.gpxFileName;
        [_exportController presentOptionsMenuFromRect:CGRectZero
                                               inView:self.view
                                             animated:YES];
        
    }
    
}

- (IBAction)menuFavoriteClicked:(id)sender {
    OAFavoriteListViewController* favController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

- (IBAction)menuGPXClicked:(id)sender {
}

- (IBAction)backButtonClicked:(id)sender
{
    [super backButtonClicked:sender];
}

- (IBAction)goRootScreen:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)onImportClicked {
    NSString* favoritesImportText = OALocalizedString(@"gpx_import_desc");
    UIAlertView* importHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:favoritesImportText delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
    [importHelpAlert show];
}

- (void)onExportClicked {
    
    if (self.gpxList.count > 0) {
        OAGPXListViewController* exportController = [[OAGPXListViewController alloc] initExport];
        [self.navigationController pushViewController:exportController animated:YES];
    } else {
        UIAlertView* exportHelpAlert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"gpx_no_tracks") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
        [exportHelpAlert show];
    }
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.gpxList.count > 0 && !_isExport)
        return 2;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 && self.gpxList.count > 0)
        return OALocalizedString(@"tracks");
    return OALocalizedString(@"gpx_import_export");
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0 && self.gpxList.count > 0)
        return [self.gpxList count];
    return [self.menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && self.gpxList.count > 0) {
        
        static NSString* const reusableIdentifierPoint = @"OAGPXTableViewCell";
        
        OAGPXTableViewCell* cell;
        cell = (OAGPXTableViewCell *)[self.gpxTableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGPXCell" owner:self options:nil];
            cell = (OAGPXTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            OAGPX* item = [self.gpxList objectAtIndex:indexPath.row];
            [cell.textView setText:item.gpxTitle];
            [cell.descriptionDistanceView setText:[_app getFormattedDistance:item.totalDistance]];
            [cell.descriptionPointsView setText:OALocalizedString(@"%d gpx_points_b", item.wptPoints)];
            if (_isExport) {
                if (indexPath.row == _selectedIndex)
                    [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
                else
                    [cell.iconView setImage:nil];
            }
        }
        
        return cell;
        
    } else {
        
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


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_isExport) {
        
        _selectedIndex = indexPath.row;
        [self.gpxTableView reloadData];
        
    } else if (indexPath.section == 0 && self.gpxList.count > 0) {
        
        OAGPX* item = [self.gpxList objectAtIndex:indexPath.row];
        
        OAGPXItemViewController* controller = [[OAGPXItemViewController alloc] initWithGPXItem:item];
        [self.navigationController pushViewController:controller animated:YES];
        
    } else {
        NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}
#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}






@end
