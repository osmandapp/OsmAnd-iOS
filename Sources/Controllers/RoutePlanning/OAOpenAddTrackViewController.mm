//
//  OAOpenAddTrackViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAOpenAddTrackViewController.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "OAGPXTrackCell.h"
#import "OASegmentTableViewCell.h"
#import "OADividerCell.h"
#import "OARoutePlanningHudViewController.h"
#import "OASaveTrackBottomSheetViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATargetPointsHelper.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OAMapActions.h"
#import "OASelectedGPXHelper.h"
#import "OAFoldersCell.h"
#import "OACollectionViewCellState.h"
#import "OAOsmAndFormatter.h"
#import "OAFoldersCollectionView.h"
#import "OAApplicationMode.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

#define kAllFoldersIndex 0
#define kVerticalMargin 16.
#define kHorizontalMargin 16.
#define kGPXCellTextLeftOffset 62.

typedef NS_ENUM(NSInteger, EOASortingMode) {
    EOAModifiedDate = 0,
    EOANameAscending,
    EOANameDescending
};

@interface OAOpenAddTrackViewController() <UITextViewDelegate, OASegmentSelectionDelegate, OAFoldersCellDelegate, UIAdaptivePresentationControllerDelegate>

@end

@implementation OAOpenAddTrackViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    EOASortingMode _sortingMode;
    EOAPlanningTrackScreenType _screenType;
    NSInteger _selectedFolderIndex;
    NSArray<NSString *> *_allFolders;
    OACollectionViewCellState *_scrollCellsState;
    OAFoldersCell *_foldersCell;
    
    BOOL _showCurrentGpx;
}

#pragma mark - Initialization

- (instancetype)initWithScreenType:(EOAPlanningTrackScreenType)screenType showCurrent:(BOOL)showCurrent
{
    self = [super init];
    if (self)
    {
        _screenType = screenType;
        _showCurrentGpx = showCurrent;
        [self postInit];
    }
    return self;
}

- (instancetype)initWithScreenType:(EOAPlanningTrackScreenType)screenType
{
    self = [super init];
    if (self)
    {
        _screenType = screenType;
        [self postInit];
    }
    return self;
}

- (void)postInit
{
    _selectedFolderIndex = kAllFoldersIndex;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _allFolders = [OAUtilities getGpxFoldersListSorted:YES shouldAddRootTracksFolder:YES];
    [self generateData];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.presentationController.delegate = self;
    
    _sortingMode = EOAModifiedDate;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    switch (_screenType)
    {
        case EOAOpenExistingTrack:
            return OALocalizedString(@"plan_route_open_existing_track");
        case EOAAddToATrack:
            return OALocalizedString(@"add_to_a_track");
        case EOAFollowTrack:
            return OALocalizedString(@"follow_track");
        case EOASelectTrack:
            return OALocalizedString(@"gpx_select_track");
        default:
            return @"";
    }
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getTableHeaderDescription
{
    return _screenType == EOAFollowTrack ? OALocalizedString(@"select_track_to_follow") : nil;
}

- (BOOL)hideFirstHeader
{
    return _screenType == EOAFollowTrack ? YES : NO;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSMutableArray *existingTracksSection = [NSMutableArray new];
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    NSArray *filteredData = [self filterData:[db getDataItems]];
    NSArray *gpxList = [NSMutableArray arrayWithArray:[self sortData:filteredData]];
    
    [existingTracksSection addObject:@{
        @"type" : [OAFoldersCell getCellIdentifier],
        @"selectedValue" : @(_selectedFolderIndex),
        @"values" : [self getFoldersList]
    }];
    
    [existingTracksSection addObject:@{ @"type" : [OADividerCell getCellIdentifier] }];
    
    [existingTracksSection addObject:@{
        @"type" : [OASegmentTableViewCell getCellIdentifier],
        @"title0" : OALocalizedString(@"shared_string_modified"),
        @"title1" : OALocalizedString(@"shared_a_z"),
        @"title2" : OALocalizedString(@"shared_z_a"),
        @"key" : @"segment_control"
    }];
    
    OASavingTrackHelper *gpxRecHelper = OASavingTrackHelper.sharedInstance;
    
    if (_showCurrentGpx && gpxRecHelper.getIsRecording)
    {
        [existingTracksSection addObject:@{
            @"type" : [OAGPXTrackCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_currently_recording_track"),
            @"distance" : [OAOsmAndFormatter getFormattedDistance:gpxRecHelper.distance],
            @"time" : [OAOsmAndFormatter getFormattedTimeInterval:0 shortFormat:YES],
            @"wpt" : [NSString stringWithFormat:@"%d", gpxRecHelper.points],
            @"key" : @"gpx_route"
        }];
    }
    
    for (OASGpxDataItem *gpx in gpxList)
    {
        [existingTracksSection addObject:@{
            @"type" : [OAGPXTrackCell getCellIdentifier],
            @"track" : gpx,
            @"title" : [gpx getNiceTitle],
            @"distance" : [OAOsmAndFormatter getFormattedDistance:gpx.totalDistance],
            @"time" : [OAOsmAndFormatter getFormattedTimeInterval:gpx.timeSpan / 1000 shortFormat:YES],
            @"wpt" : [NSString stringWithFormat:@"%d", gpx.wptPoints],
            @"key" : @"gpx_route"
        }];
    }
    [existingTracksSection addObject:@{ @"type" : [OADividerCell getCellIdentifier] }];
    [data addObject:existingTracksSection];
    _data = data;
}

- (NSArray<NSDictionary *> *)getFoldersList
{
    NSArray *folderNames = _allFolders;
    
    NSMutableArray *folderButtonsData = [NSMutableArray new];
    [folderButtonsData addObject:@{
        @"title" : OALocalizedString(@"shared_string_all"),
        @"img" : @""
    }];
    
    for (int i = 0; i < folderNames.count; i++)
    {
        [folderButtonsData addObject:@{
            @"title" : folderNames[i],
            @"img" : @"ic_custom_folder"
        }];
    }
    return folderButtonsData;
}

- (NSArray *)filterData:(NSArray *)data
{
    if (_selectedFolderIndex == kAllFoldersIndex)
    {
        return data;
    }
    else
    {
        NSString *selectedFolderName = _allFolders[_selectedFolderIndex - 1];
        if ([selectedFolderName isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")])
            selectedFolderName = @"";
        
        return [data filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OASGpxDataItem *object, NSDictionary *bindings) {
            return [object.gpxFolderName isEqualToString:selectedFolderName];
        }]];
    }
}

- (NSArray *)sortData:(NSArray *)data
{
    NSArray *sortedData = [data sortedArrayUsingComparator:^NSComparisonResult(OASGpxDataItem *obj1, OASGpxDataItem *obj2) {
        switch (_sortingMode) {
            case EOAModifiedDate:
            {
                NSDate *time1 = [OAUtilities getFileLastModificationDate:obj1.gpxFilePath];
                NSDate *time2 = [OAUtilities getFileLastModificationDate:obj2.gpxFilePath];
                return [time2 compare:time1];
            }
            case EOANameAscending:
                return [obj1.gpxTitle compare:obj2.gpxTitle];
            case EOANameDescending:
                return  [obj2.gpxTitle compare:obj1.gpxTitle];
            default:
                break;
        }
    }];
    return sortedData;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else if ([item[@"type"] isEqualToString:[OAFoldersCell getCellIdentifier]])
        return 52;
    
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OASegmentTableViewCell getCellIdentifier]])
    {
        OASegmentTableViewCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OASegmentTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
            [cell.segmentControl insertSegmentWithTitle:item[@"title2"] atIndex:2 animated:NO];
        }
        if (cell)
        {
            [cell.segmentControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
            UIFont *font = [UIFont scaledSystemFontOfSize:14.];
            [cell.segmentControl setTitleTextAttributes:@{ NSFontAttributeName : font } forState:UIControlStateNormal];
            [cell.segmentControl setTitleTextAttributes:@{ NSFontAttributeName : font } forState:UIControlStateSelected];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAGPXTrackCell getCellIdentifier]])
    {
        OAGPXTrackCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAGPXTrackCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAGPXTrackCell getCellIdentifier] owner:self options:nil];
            cell = (OAGPXTrackCell *)[nib objectAtIndex:0];
            cell.separatorView.backgroundColor = [UIColor colorNamed:ACColorNameCustomSeparator];
            cell.distanceImageView.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.timeImageView.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.wptImageView.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.distanceLabel.text = item[@"distance"];
            cell.timeLabel.text = item[@"time"];
            cell.wptLabel.text = item[@"wpt"];
            cell.separatorView.hidden = indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 2;
        }
        return cell;
    }
    else if ([type isEqualToString:[OAFoldersCell getCellIdentifier]])
    {
        if (_foldersCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCell getCellIdentifier] owner:self options:nil];
            _foldersCell = (OAFoldersCell *)[nib objectAtIndex:0];
            _foldersCell.selectionStyle = UITableViewCellSelectionStyleNone;
            _foldersCell.backgroundColor = UIColor.clearColor;
            _foldersCell.collectionView.backgroundColor = UIColor.clearColor;
            _foldersCell.collectionView.foldersDelegate = self;
            _foldersCell.collectionView.cellIndex = indexPath;
            _foldersCell.collectionView.state = _scrollCellsState;
        }
        if (_foldersCell)
        {
            [_foldersCell.collectionView setValues:item[@"values"] withSelectedIndex:[item[@"selectedValue"] intValue]];
            [_foldersCell.collectionView reloadData];
        }
        return _foldersCell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAFoldersCell getCellIdentifier]])
    {
        OAFoldersCell *folderCell = (OAFoldersCell *)cell;
        [folderCell.collectionView updateContentOffset];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    OASGpxDataItem* track = item[@"track"];
    switch (_screenType) {
        case EOAOpenExistingTrack:
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            [self closeBottomSheetDelegate];
            [self.delegate onFileSelected:track.gpxFilePath];
            break;
        }
        case EOASelectTrack:
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            [self closeBottomSheetDelegate];
            [self.delegate onFileSelected:track.gpxFilePath];
            break;
        }
        case EOAAddToATrack:
        {
            OASGpxDataItem* track = item[@"track"];
            NSString *filename = nil;
            if (track)
                filename = track.gpxFileName;
            if (self.delegate)
                [self.delegate onFileSelected:filename];
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case EOAFollowTrack:
        {
            OASGpxDataItem *track = item[@"track"];
            NSString *filePath = track.gpxFilePath;
            NSDictionary<NSString *, OASGpxFile *> *activeGpx = OASelectedGPXHelper.instance.activeGpx;
            if ([activeGpx.allKeys containsObject:filePath])
            {
                [OAAppSettings.sharedManager showGpx:@[filePath]];
            }
            
            OASKFile *file = [[OASKFile alloc] initWithFilePath:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:track.gpxFilePath]];
            OASGpxFile *doc = [OASGpxUtilities.shared loadGpxFileFile:file];
            
            OAApplicationMode *mode = [self getRouteProfile:doc];
            if (mode)
            {
                [OARoutingHelper.sharedInstance setAppMode:mode];
                [OsmAndApp.instance initVoiceCommandPlayer:mode warningNoneProvider:YES showDialog:NO force:NO];
            }
            
            if (doc.getNonEmptySegmentsCount > 1)
            {
                OATrackSegmentsViewController *trackSegments = [[OATrackSegmentsViewController alloc] initWithFile:doc];
                trackSegments.delegate = self;
                [self.navigationController pushViewController:trackSegments animated:YES];
                return;
            }
            else
            {
                [[OARootViewController instance].mapPanel.mapActions setGPXRouteParams:track];
                [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
                [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
                if (self.delegate)
                    [self.delegate onFileSelected:filePath];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
    }
}

- (OAApplicationMode *)getRouteProfile:(OASGpxFile *)gpxFile
{
    NSArray<OASWptPt *> *points = [gpxFile getRoutePoints];
    if (points && points.count > 0)
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:[points[0] getProfileType] def:nil];
        if (mode)
            return mode;
    }
    return nil;
}

#pragma mark - Aditions

- (BOOL)isShowCurrentGpx
{
    return _screenType == EOAAddToATrack;
}

#pragma mark - Selectors

- (void)closeBottomSheetDelegate
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeBottomSheet)])
        [self.delegate closeBottomSheet];
}

- (void)onLeftNavbarButtonPressed
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (_screenType == EOAFollowTrack)
            [self closeBottomSheetDelegate];
    }];
}

- (void)segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl*)sender;
    if (segment)
    {
        if (segment.selectedSegmentIndex == 0)
            _sortingMode = EOAModifiedDate;
        else if (segment.selectedSegmentIndex == 1)
            _sortingMode = EOANameAscending;
        else if (segment.selectedSegmentIndex == 2)
            _sortingMode = EOANameDescending;
        [self generateData];
        
        NSMutableArray *pathsToReload = [NSMutableArray arrayWithArray:self.tableView.indexPathsForVisibleRows];
        [pathsToReload removeObjectsInRange:NSMakeRange(0, 3)];
        [self.tableView reloadRowsAtIndexPaths:pathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - OASegmentSelectionDelegate

- (void)onSegmentSelected:(NSInteger)position gpx:(OASGpxFile *)gpx
{
    if (self.delegate)
    {
        [self.delegate onSegmentSelected:position gpx:gpx];
        [OARootViewController.instance dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    _selectedFolderIndex = index;
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController
{
    if (_screenType == EOAFollowTrack)
        [self closeBottomSheetDelegate];
}

@end
