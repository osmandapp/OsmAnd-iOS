//
//  OASelectTrackFolderViewController.m
//  OsmAnd
//
//  Created by nnngrach on 05.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASelectTrackFolderViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OARightIconTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OAAddTrackFolderViewController.h"
#import "OsmAndApp.h"
#import "OALoadGpxTask.h"
#import "OATableViewCustomHeaderView.h"
#import "GeneratedAssetSymbols.h"

#define kAddNewFolderSection 0
#define kFoldersListSection 1

@interface OASelectTrackFolderViewController() <OAAddTrackFolderDelegate>

@end

@implementation OASelectTrackFolderViewController
{
    OAGPX *_gpx;
    NSString *_selectedFolderName;
    NSString *_prefixToHide;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

#pragma mark - Initialization

- (instancetype)initWithGPX:(OAGPX *)gpx
{
    self = [super init];
    if (self)
    {
        _selectedFolderName = gpx.gpxFolderName;
        if ([_selectedFolderName isEqualToString:@""])
            _selectedFolderName = OALocalizedString(@"shared_string_gpx_tracks");
        [self reloadData];
    }
    return self;
}

- (instancetype)initWithSelectedFolderName:(NSString *)selectedFolderName;
{
    self = [super init];
    if (self)
    {
        _selectedFolderName = selectedFolderName;
        [self reloadData];
    }
    return self;
}

- (instancetype)initWithSelectedFolderName:(NSString *)selectedFolderName prefixToHide:(NSString*)prefixToHide
{
    self = [super init];
    if (self)
    {
        _selectedFolderName = selectedFolderName;
        _prefixToHide = prefixToHide;
        [self reloadData];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    self.tableView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (_delegate && [_delegate respondsToSelector:@selector(onFolderSelectCancelled)])
        [_delegate onFolderSelectCancelled];
    [super viewWillDisappear:animated];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"select_folder");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData:(NSMutableArray<NSString *> *)allFolderNames foldersData:(NSMutableDictionary *)foldersData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : [OARightIconTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"add_folder"),
            @"img" : @"ic_custom_add",
        },
    ]];
    
    NSMutableArray *cellFoldersData = [NSMutableArray new];
    for (NSString *folderName in allFolderNames)
    {
        if (_prefixToHide && [folderName hasPrefix:_prefixToHide])
            continue;
        
        NSArray *folderItems = foldersData[folderName];
        int tracksCount = folderItems ? folderItems.count : 0;
        NSString *selectedFolderName = _selectedFolderName.length == 0 ? OALocalizedString(@"shared_string_gpx_tracks") : _selectedFolderName;
        [cellFoldersData addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"header" : OALocalizedString(@"plan_route_folder"),
            @"title" : folderName,
            @"description" : [NSString stringWithFormat:@"%i", tracksCount],
            @"isSelected" : [NSNumber numberWithBool:[folderName isEqualToString: selectedFolderName]],
            @"img" : @"ic_custom_folder"
        }];
    }
    
    [data addObject: [NSArray arrayWithArray:cellFoldersData]];
    _data = data;
}

- (void)reloadData
{
    NSArray<NSString *> *allFoldersNames = [OAUtilities getGpxFoldersListSorted:YES shouldAddRootTracksFolder:YES];
        
    OALoadGpxTask *task = [[OALoadGpxTask alloc] init];
    [task execute:^(NSDictionary<NSString *, NSArray<OAGpxInfo *> *>* gpxFolders) {
        [self generateData:allFoldersNames foldersData:gpxFolders];
        [self.tableView reloadData];
    }];
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    NSDictionary *item = _data[section].firstObject;
    return item[@"header"] ? item[@"header"] : @" ";
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    OATableViewCustomHeaderView *vw = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    vw.label.text = [title upperCase];
    vw.label.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    return vw;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    return [OATableViewCustomHeaderView getHeight:title width:self.tableView.bounds.size.width];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        cell.titleLabel.text = item[@"title"];
        [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }

    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = (OASimpleTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            cell.titleLabel.numberOfLines = 3;
            cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            [cell.titleLabel setText:item[@"title"]];
            [cell.descriptionLabel setText:item[@"description"]];
            [cell.leftIconView setImage:[UIImage imageNamed:item[@"img"]]];
            
            if ([item[@"isSelected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAddNewFolderSection)
    {
        OAAddTrackFolderViewController * addFolderVC = [[OAAddTrackFolderViewController alloc] init];
        addFolderVC.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addFolderVC];
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }
    else if (indexPath.section == kFoldersListSection)
    {
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        if (![item[@"isSelected"] boolValue] && _delegate)
            [_delegate onFolderSelected:item[@"title"]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - OAAddTrackFolderDelegate

- (void)onTrackFolderAdded:(NSString *)folderName 
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *controllerToDismiss = self.presentingViewController ?: self;
        [controllerToDismiss dismissViewControllerAnimated:YES completion:^{
            [_delegate onFolderAdded:folderName];
        }];
    });
}

@end
