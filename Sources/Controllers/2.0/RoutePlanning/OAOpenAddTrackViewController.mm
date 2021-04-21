//
//  OAOpenAddTrackViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAOpenAddTrackViewController.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDatabase.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OsmAndApp.h"
#import "OAGPXTrackCell.h"
#import "OASegmentTableViewCell.h"
#import "OADividerCell.h"
#import "OARoutePlanningHudViewController.h"
#import "OASaveTrackBottomSheetViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OATargetPointsHelper.h"
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OAMapActions.h"
#import "OASelectedGPXHelper.h"
#import "OAFoldersCell.h"
#import "OACollectionViewCellState.h"

#define kGPXTrackCell @"OAGPXTrackCell"
#define kDividerCell @"OADividerCell"
#define kCellTypeSegment @"OASegmentTableViewCell"
#define kFoldersCell @"OAFoldersCell"
#define kAllFoldersKey @"kAllFoldersKey"
#define kFolderKey @"kFolderKey"
#define kAllFoldersIndex 0
#define kVerticalMargin 16.
#define kHorizontalMargin 16.
#define kGPXCellTextLeftOffset 62.

typedef NS_ENUM(NSInteger, EOASortingMode) {
    EOAModifiedDate = 0,
    EOANameAscending,
    EOANameDescending
};

@interface OAOpenAddTrackViewController() <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, OASegmentSelectionDelegate, OAFoldersCellDelegate>

@end

@implementation OAOpenAddTrackViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    EOASortingMode _sortingMode;
    EOAPlanningTrackScreenType _screenType;
    int _selectedFolderIndex;
    NSArray<NSString *> *_allFolders;
    OACollectionViewCellState *_scrollCellsState;
}

- (instancetype) initWithScreenType:(EOAPlanningTrackScreenType)screenType
{
    self = [super initWithNibName:@"OAOpenAddTrackViewController"
                           bundle:nil];
    if (self)
    {
        _screenType = screenType;
        [self commonInit];
        [self generateData];
    }
    return self;
}

- (void) commonInit
{
    _selectedFolderIndex = kAllFoldersIndex;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    [self updateAllFoldersList];
}

- (void) updateAllFoldersList
{
    _allFolders = [OAUtilities getGpxFoldersListSorted:YES shouldAddTracksFolder:YES];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _sortingMode = EOAModifiedDate;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(-16, 0, 0, 0);
    if (_screenType == EOAAddToATrack)
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"route_between_points_add_track_desc") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
    else if (_screenType == EOAFollowTrack)
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"select_track_to_follow") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
}

- (void) applyLocalization
{
    [super applyLocalization];
    switch (_screenType) {
        case EOAOpenExistingTrack:
            self.titleLabel.text = OALocalizedString(@"plan_route_open_existing_track");
            break;
        case EOAAddToATrack:
            self.titleLabel.text = OALocalizedString(@"add_to_track");
            break;
        case EOAFollowTrack:
            self.titleLabel.text = OALocalizedString(@"follow_track");
            break;
        default:
            break;
    }
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSString *headerDescription = _screenType == EOAAddToATrack ? OALocalizedString(@"route_between_points_add_track_desc") : OALocalizedString(@"select_track_to_follow");
    if (_screenType != EOAOpenExistingTrack)
    {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:headerDescription font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
            [self.tableView reloadData];
        } completion:nil];
    }
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    NSMutableArray *existingTracksSection = [NSMutableArray new];
    OAGPXDatabase *db = [OAGPXDatabase sharedDb];
    NSArray *filteredData = [self filterData:db.gpxList];
    NSArray *gpxList = [NSMutableArray arrayWithArray:[self sortData:filteredData]];
    
    [existingTracksSection addObject:@{
        @"type" : kFoldersCell,
        @"selectedValue" : [NSNumber numberWithInt:_selectedFolderIndex],
        @"values" : [self getFoldersList]
    }];
    
    [existingTracksSection addObject:@{ @"type" : kDividerCell }];
    
    [existingTracksSection addObject:@{
        @"type" : kCellTypeSegment,
        @"title0" : OALocalizedString(@"osm_modified"),
        @"title1" : OALocalizedString(@"shared_a_z"),
        @"title2" : OALocalizedString(@"shared_z_a"),
        @"key" : @"segment_control"
    }];
    
    OsmAndAppInstance app = OsmAndApp.instance;
    
    /*if ([self isShowCurrentGpx])
    {
        [existingTracksSection addObject:@{
                @"type" : kGPXTrackCell,
                @"title" : OALocalizedString(@"track_recording_name"),
                @"distance" : [app getFormattedDistance:0],
                @"time" : [app getFormattedTimeInterval:0 shortFormat:YES],
                @"wpt" : [NSString stringWithFormat:@"%d", 0],
                @"key" : @"gpx_route"
            }];
    }*/
    
    for (OAGPX *gpx in gpxList)
    {
        [existingTracksSection addObject:@{
                @"type" : kGPXTrackCell,
                @"track" : gpx,
                @"title" : [gpx getNiceTitle],
                @"distance" : [app getFormattedDistance:gpx.totalDistance],
                @"time" : [app getFormattedTimeInterval:gpx.timeSpan shortFormat:YES],
                @"wpt" : [NSString stringWithFormat:@"%d", gpx.wptPoints],
                @"key" : @"gpx_route"
            }];
    }
    [existingTracksSection addObject:@{ @"type" : kDividerCell }];
    [data addObject:existingTracksSection];
    _data = data;
}

- (NSArray<NSDictionary *> *) getFoldersList
{
    NSArray *folderNames = _allFolders;
    
    NSMutableArray *folderButtonsData = [NSMutableArray new];
    [folderButtonsData addObject:@{
        @"title" : OALocalizedString(@"shared_string_all"),
        @"img" : @"",
        @"type" : kAllFoldersKey}];
    
    for (int i = 0; i < folderNames.count; i++)
    {
        [folderButtonsData addObject:@{
            @"title" : folderNames[i],
            @"img" : @"ic_custom_folder",
            @"type" : kFolderKey}];
    }
    return folderButtonsData;
}

- (NSArray *) filterData:(NSArray *)data
{
    if (_selectedFolderIndex == kAllFoldersIndex)
    {
        return data;
    }
    else
    {
        NSString *selectedFolderName = _allFolders[_selectedFolderIndex - 1];
        if ([selectedFolderName isEqualToString:OALocalizedString(@"tracks")])
            selectedFolderName = @"";
        
        return [data filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OAGPX *object, NSDictionary *bindings) {
            NSString *folderName = object.gpxFilePath.stringByDeletingLastPathComponent;
            return [folderName isEqualToString:selectedFolderName];
        }]];
    }
}

- (NSArray *) sortData:(NSArray *)data
{
    NSArray *sortedData = [data sortedArrayUsingComparator:^NSComparisonResult(OAGPX *obj1, OAGPX *obj2) {
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

- (BOOL) isShowCurrentGpx
{
    return _screenType == EOAAddToATrack;
}

- (void) dismissViewController
{
    if (self.delegate)
        [self.delegate closeBottomSheet];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:@"OADividerCell"])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else if ([item[@"type"] isEqualToString:kFoldersCell])
        return 52;
    
    return UITableViewAutomaticDimension;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    if ([type isEqualToString:kCellTypeSegment])
    {
        static NSString* const identifierCell = @"OASegmentTableViewCell";
        OASegmentTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASegmentTableViewCell" owner:self options:nil];
            cell = (OASegmentTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
            [cell.segmentControl insertSegmentWithTitle:item[@"title2"] atIndex:2 animated:NO];
        }
        if (cell)
        {
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl setTitle:item[@"title0"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:item[@"title1"] forSegmentAtIndex:1];
        }
        return cell;
    }
    else if ([type isEqualToString:kGPXTrackCell])
    {
        static NSString* const identifierCell = kGPXTrackCell;
        OAGPXTrackCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kGPXTrackCell owner:self options:nil];
            cell = (OAGPXTrackCell *)[nib objectAtIndex:0];
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
            cell.distanceImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.timeImageView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.wptImageView.tintColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.distanceLabel.text = item[@"distance"];
            cell.timeLabel.text = item[@"time"];
            cell.wptLabel.text = item[@"wpt"];
            cell.separatorView.hidden = indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 2;
        }
        return cell;
    }
    else if ([type isEqualToString:kFoldersCell])
    {
        static NSString* const identifierCell = kFoldersCell;
        OAFoldersCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAFoldersCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.collectionView.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.delegate = self;
            cell.cellTag = kFoldersCell;
            cell.state = _scrollCellsState;
            [cell setValues:item[@"values"] withSelectedIndex:(int)[item[@"selectedValue"] intValue]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kDividerCell])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:kDividerCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDividerCell owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
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
     if ([type isEqualToString:kFoldersCell])
     {
         OAFoldersCell *folderCell = (OAFoldersCell *)cell;
         if (![_scrollCellsState containsValueForKey:kFoldersCell])
         {
             CGPoint offset = [folderCell calculateShowingOffset:(NSInteger)[item[@"selectedValue"] integerValue]];
             [_scrollCellsState setOffset:offset forKey:kFoldersCell];
         }
         [folderCell updateContentOffset];
     }
 }

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    OAGPX* track = item[@"track"];
    switch (_screenType) {
        case EOAOpenExistingTrack:
        {
            if (self.delegate)
                [self.delegate closeBottomSheet];
            [self dismissViewControllerAnimated:YES completion:nil];
            [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] initWithFileName:track.gpxFileName]];
            break;
        }
        case EOAAddToATrack:
        {
            OAGPX* track = item[@"track"];
            NSString *filename = nil;
            if (track)
                filename = track.gpxFileName;
            if (self.delegate)
                [self.delegate onFileSelected:filename];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case EOAFollowTrack:
        {
            OAGPX* track = item[@"track"];
            NSString *filePath = track.gpxFilePath;
            const auto& activeGpx = OASelectedGPXHelper.instance.activeGpx;
            if (activeGpx.find(QString::fromNSString(filePath)) == activeGpx.end())
            {
                [OAAppSettings.sharedManager showGpx:@[filePath]];
            }
            
            OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:[OsmAndApp.instance.gpxPath stringByAppendingPathComponent:track.gpxFilePath]];
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

- (void) segmentChanged:(id)sender
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

// MARK: OASegmentSelectionDelegate

- (void)onSegmentSelected:(NSInteger)position gpx:(OAGPXDocument *)gpx
{
    if (self.delegate)
        [self.delegate onSegmentSelected:position gpx:gpx];
}

#pragma mark - OAFoldersCellDelegate

- (void) onItemSelected:(int)index type:(NSString *)type
{
    _selectedFolderIndex = index;
    [self generateData];
    [self.tableView reloadData];
}

@end
