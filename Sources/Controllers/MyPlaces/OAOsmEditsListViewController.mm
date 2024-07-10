//
//  OAOsmEditsListViewController.m
//  OsmAnd
//
//  Created by Paul on 4/17/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditsListViewController.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAEntity.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAEditPOIData.h"
#import "OAButtonTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAOsmEditsLayer.h"
#import "OAOsmEditActionsViewController.h"
#import "OAMapLayers.h"
#import "OAOsmNoteViewController.h"
#import "OAOsmUploadPOIViewController.h"
#import "OAMultiselectableHeaderView.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

typedef NS_ENUM(NSInteger, EOAEditsListType)
{
    EDITS_ALL = 0,
    EDITS_POI,
    EDITS_NOTES
};

@interface OAOsmEditsListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate, UIScrollViewDelegate, OAOsmEditingBottomSheetDelegate, OAMultiselectableHeaderDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *segmentContainerView;

@end

@implementation OAOsmEditsListViewController
{
    EOAEditsListType _screenType;
    OAPOIHelper *_poiHelper;
    
    NSArray *_data;
    NSArray *_pendingNotes;
    
    OAMultiselectableHeaderView *_headerView;
    
    UIBarButtonItem *_deleteButton;
    UIBarButtonItem *_uploadButton;
    UISearchController *_searchController;
    
    BOOL _popToParent;
    BOOL _isSearchActive;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    _poiHelper = [OAPOIHelper sharedInstance];
    [self applySafeAreaMargins];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    self.segmentContainerView.backgroundColor = [[UIColor colorNamed:ACColorNameNavBarBgColorPrimary] colorWithAlphaComponent:1.0];
    
    _headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 55.0)];
    _headerView.delegate = self;
    [self setupView];
    
    _tableView.estimatedRowHeight = kEstimatedRowHeight;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    
    _isSearchActive = NO;
}

- (void) setShouldPopToParent:(BOOL)shouldPop
{
    _popToParent = shouldPop;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    _deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_trash"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonPressed:)];
    _uploadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_upload_to_openstreetmap_outlined"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadButtonPressed:)];
    [self.navigationController.navigationBar.topItem setRightBarButtonItems:@[_uploadButton, _deleteButton] animated:YES];
    _deleteButton.accessibilityLabel = OALocalizedString(@"shared_string_delete");
    _uploadButton.accessibilityLabel = OALocalizedString(@"upload_to_openstreetmap");
    self.tabBarController.navigationItem.title = OALocalizedString(@"osm_edits_title");
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.tabBarController.navigationItem.searchController = _searchController;
    [self setupSearchController:NO filtered:NO];
    self.definesPresentationContext = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.definesPresentationContext = NO;
}

-(void) applyLocalization
{
    [_segmentControl setTitle:OALocalizedString(@"shared_string_all") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"osm_edits_edits_label") forSegmentAtIndex:1];
    [_segmentControl setTitle:OALocalizedString(@"osm_edits_notes") forSegmentAtIndex:2];
    [_segmentControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont scaledSystemFontOfSize:14.] } forState:UIControlStateNormal];
    [_segmentControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont scaledSystemFontOfSize:14.] } forState:UIControlStateSelected];
}

-(void)setupView
{
    [_headerView setTitleText:[self getLocalizedHeaderTitle]];
    NSMutableArray *dataArr = [NSMutableArray new];
    NSArray *poi = [[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints];
    NSArray *notes = [[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints];
    if (_screenType == EDITS_ALL || _screenType == EDITS_POI)
    {
        for (OAOpenStreetMapPoint *p in poi)
        {
            NSString *poiType = [p.getEntity getTagFromString:POI_TYPE_TAG];
            poiType = poiType ? [poiType lowerCase] : @"";
            NSString *name = p.getName;
            [dataArr addObject:@{
                                 @"title" : name.length == 0 ? [self getDescription:p] : name,
                                 @"poi_type" : poiType,
                                 @"description" : [self getDescription:p],
                                 @"item" : p
                                 }];
        }
    }
    if (_screenType == EDITS_ALL || _screenType == EDITS_NOTES)
    {
        for (OAOsmPoint *p in notes)
        {
            [dataArr addObject:@{
                                 @"title" : p.getName,
                                 @"description" : [self getDescription:p],
                                 @"item" : p
                                 }];
        }
    }
    _data = [NSArray arrayWithArray:dataArr];
}

-(NSString *)getDescription:(OAOsmPoint *)point
{
    NSString *actionStr = point.getLocalizedAction;
    NSString *type = [OAOsmEditingPlugin getCategory:point];
    NSMutableString *result = [NSMutableString new];
    [result appendString:actionStr];
    if (type)
    {
        [result appendString:@" • "];
        [result appendString:type];
    }
    if (point.getGroup == POI && point.getAction != CREATE)
    {
        [result appendString:@" • "];
        [result appendString:OALocalizedString(@"osm_poi_id_label")];
        [result appendString:@" "];
        [result appendString:[NSString stringWithFormat:@"%lld", point.getId]];
    }
    return result;
}

- (NSString *) getLocalizedHeaderTitle
{
    switch (_screenType)
    {
        case EDITS_ALL:
            return OALocalizedString(@"osm_edits_all");
        case EDITS_POI:
            return OALocalizedString(@"osm_edits_poi");
        case EDITS_NOTES:
            return OALocalizedString(@"osm_edits_notes");
        default:
            return nil;
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

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return _isSearchActive ? 0.0 : 55.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0 && !_isSearchActive)
        return _headerView;
    
    return nil;
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSDictionary *translatedNames = [_poiHelper getAllTranslatedNames:NO];
    OAPOIType *poiType = translatedNames[item[@"poi_type"]];
    OAButtonTableViewCell* cell;
    cell = (OAButtonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAButtonTableViewCell *)[nib objectAtIndex:0];
        [cell.button setTitle:nil forState:UIControlStateNormal];
        [cell.button setTintColor:[UIColor colorNamed:ACColorNameIconColorDefault]];
        [cell.button.imageView setContentMode:UIViewContentModeCenter];
    }
    
    if (cell)
    {
        [cell.titleLabel setText:item[@"title"]];
        [cell.descriptionLabel setText:item[@"description"]];
        [cell.leftIconView setImage:poiType ? poiType.icon : [UIImage imageNamed:@"ic_custom_osm_note_unresolved"]];
        [cell.button setImage:[UIImage templateImageNamed:@"ic_custom_overflow_menu.png"] forState:UIControlStateNormal];
        [cell.button setTag:indexPath.row];
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:@selector(overflowButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.tableView.isEditing)
        return;
    NSDictionary *item = [self getItem:indexPath];
    OAOsmPoint *p = item[@"item"];
    [self.navigationController popToRootViewControllerAnimated:YES];
    if (p)
    {
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.osmEditsLayer getTargetPoint:p];
        newTarget.centerMap = YES;
        [mapPanel showContextMenu:newTarget];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (IBAction)onSegmentChanged:(id)sender {
    switch (_segmentControl.selectedSegmentIndex)
    {
        case 0:
        {
            if (_screenType != EDITS_ALL)
            {
                _screenType = EDITS_ALL;
                [self setupView];
                [_tableView reloadData];
                return;
            }
        }
        case 1:
        {
            if (_screenType != EDITS_POI)
            {
                _screenType = EDITS_POI;
                [self setupView];
                [_tableView reloadData];
                return;
            }
        }
        case 2:
        {
            if (_screenType != EDITS_NOTES)
            {
                _screenType = EDITS_NOTES;
                [self setupView];
                [_tableView reloadData];
                return;
            }
        }
    }
}

- (IBAction)deleteButtonPressed:(id)sender {
    [self.tableView beginUpdates];
    BOOL shouldEdit = ![self.tableView isEditing];
    
    if (shouldEdit)
    {
        if (@available(iOS 16.0, *))
            [_uploadButton setHidden:YES];
        else
            [_uploadButton setEnabled:NO];
    }
    else
    {
        if (@available(iOS 16.0, *))
            [_uploadButton setHidden:NO];
        else
            [_uploadButton setEnabled:YES];

        NSArray *indexes = [self.tableView indexPathsForSelectedRows];
        if (indexes.count > 0)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:
                                        [NSString stringWithFormat:OALocalizedString(@"osm_confirm_bulk_delete"), indexes.count]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                for (NSIndexPath *path in indexes)
                {
                    NSDictionary *item = [self getItem:path];
                    OAOsmPoint *point = item[@"item"];
                    if (point)
                    {
                        if (point.getGroup == POI)
                            [[OAOsmEditsDBHelper sharedDatabase] deletePOI:(OAOpenStreetMapPoint *)point];
                        else
                            [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:(OAOsmNotePoint *)point];
                    }
                }
                [self setupView];
                [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationFade];
                [[OsmAndApp instance].osmEditsChangeObservable notifyEvent];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    [self.tableView setEditing:shouldEdit animated:YES];
    [self.tableView endUpdates];
}

- (IBAction)uploadButtonPressed:(id)sender {
    [self.tableView beginUpdates];
    BOOL shouldEdit = ![self.tableView isEditing];

    if (shouldEdit)
    {
        if (@available(iOS 16.0, *))
            [_deleteButton setHidden:YES];
        else
            [_deleteButton setEnabled:NO];
    }
    else
    {
        if (@available(iOS 16.0, *))
            [_deleteButton setHidden:NO];
        else
            [_deleteButton setEnabled:YES];

        NSArray *indexes = [self.tableView indexPathsForSelectedRows];
        NSMutableArray *edits = [NSMutableArray new];
        NSMutableArray *notes = [NSMutableArray new];
        
        for (NSIndexPath *indexPath in indexes)
        {
            OAOsmPoint *p = [self getItem:indexPath][@"item"];
            if (p.getGroup == POI)
                [edits addObject:p];
            else
                [notes addObject:p];
        }
        if (edits.count > 0)
        {
            OAOsmUploadPOIViewController *editsBottomsheet = [[OAOsmUploadPOIViewController alloc] initWithPOIItems:edits];
            editsBottomsheet.delegate = self;
            _pendingNotes = notes;
            [[OARootViewController instance].mapPanel.navigationController pushViewController:editsBottomsheet animated:YES];
            
        }
        else if (notes.count > 0)
        {
            _pendingNotes = nil;
            OAOsmNoteViewController *notesBottomsheet = [[OAOsmNoteViewController alloc] initWithEditingPlugin:(OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class] points:notes type:EOAOsmNoteViewConrollerModeUpload];
            notesBottomsheet.delegate = self;
            [[OARootViewController instance].mapPanel.navigationController pushViewController:notesBottomsheet animated:YES];
        }
    
    }
    [self.tableView setEditing:shouldEdit animated:YES];
    [self.tableView endUpdates];
}

-(void) overflowButtonPressed:(UIButton *)sender
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
    OAOsmEditActionsViewController *bottomSheet = [[OAOsmEditActionsViewController alloc] initWithPoint:item[@"item"]];
    bottomSheet.delegate = self;
    [bottomSheet show];
}

#pragma mark - OAOsmEditingBottomSheetDelegate

-(void)refreshData
{
    [self setupView];
    [_tableView reloadData];
}

-(void)uploadFinished:(BOOL)hasError
{
    [self refreshData];
    if (_pendingNotes && _pendingNotes.count > 0 && !hasError)
    {
        OAOsmNoteViewController *notesBottomsheet = [[OAOsmNoteViewController alloc] initWithEditingPlugin:(OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class] points:_pendingNotes type:EOAOsmNoteViewConrollerModeUpload];
        notesBottomsheet.delegate = self;
        [[OARootViewController instance].mapPanel.navigationController pushViewController:notesBottomsheet animated:YES];
    }
    _pendingNotes = nil;
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
    
    [self.tableView beginUpdates];
    if (value)
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.tableView endUpdates];
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
        UIEdgeInsets insets = [_tableView contentInset];
        [_tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardBounds.size.height, insets.right)];
        [_tableView setScrollIndicatorInsets:_tableView.contentInset];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [_tableView contentInset];
        [_tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0.0, insets.right)];
        [_tableView setScrollIndicatorInsets:_tableView.contentInset];
    } completion:nil];
}

// MARK: UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (searchController.isActive && searchController.searchBar.searchTextField.text.length == 0)
    {
        _isSearchActive = YES;
        [self setupSearchController:YES filtered:NO];
        [self setupView];
        [_tableView reloadData];
    }
    else if (searchController.isActive && searchController.searchBar.searchTextField.text.length > 0)
    {
        [self setupSearchController:NO filtered:YES];
        NSMutableArray *filteredItems = [NSMutableArray array];
        NSArray *poi = [[OAOsmEditsDBHelper sharedDatabase] getOpenstreetmapPoints];
        NSArray *notes = [[OAOsmBugsDBHelper sharedDatabase] getOsmBugsPoints];
        if (_screenType == EDITS_ALL || _screenType == EDITS_POI)
        {
            for (OAOpenStreetMapPoint *p in poi)
            {
                NSString *poiType = [p.getEntity getTagFromString:POI_TYPE_TAG];
                poiType = poiType ? [poiType lowerCase] : @"";
                NSString *name = p.getName;
                NSRange nameTagRange = [name rangeOfString:searchController.searchBar.searchTextField.text options:NSCaseInsensitiveSearch];
                if (nameTagRange.location != NSNotFound)
                {
                    [filteredItems addObject:@{
                        @"title" : name.length == 0 ? [self getDescription:p] : name,
                        @"poi_type" : poiType,
                        @"description" : [self getDescription:p],
                        @"item" : p
                    }];
                }
            }
        }
        if (_screenType == EDITS_ALL || _screenType == EDITS_NOTES)
        {
            for (OAOsmPoint *p in notes)
            {
                NSRange nameTagRange = [p.getName rangeOfString:searchController.searchBar.searchTextField.text options:NSCaseInsensitiveSearch];
                if (nameTagRange.location != NSNotFound)
                {
                    [filteredItems addObject:@{
                        @"title" : p.getName,
                        @"description" : [self getDescription:p],
                        @"item" : p
                    }];
                }
            }
        }
        _data = [NSArray arrayWithArray:filteredItems];
        [_tableView reloadData];
    }
    else
    {
        _isSearchActive = NO;
        [self setupSearchController:NO filtered:NO];
        [self setupView];
        [_tableView reloadData];
    }
}

// MARK: UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
    searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > 0)
        self.segmentContainerView.backgroundColor = self.navigationController.navigationBar.scrollEdgeAppearance.backgroundColor;
    else if (scrollView.contentOffset.y <= 0)
        self.segmentContainerView.backgroundColor = [[UIColor colorNamed:ACColorNameNavBarBgColorPrimary] colorWithAlphaComponent:1.0];
}

@end
