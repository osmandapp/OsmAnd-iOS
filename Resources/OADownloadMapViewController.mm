//
//  OADownloadMapViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADownloadMapViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "OASelectMapSourceViewController.h"
#import "OAMapRendererView.h"

#include "Localization.h"
#include "OASizes.h"

#import "OAMenuSimpleCell.h"
#import "OASettingsTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OAPreviewZoomLevelsCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OATableViewCustomHeaderView.h"
#import "OATableViewCustomFooterView.h"

#define kHeaderId @"TableViewSectionHeader"
#define kFooterId @"TableViewSectionFooter"
#define kCellTypeZoom @"time_cell"
#define kCellTypePicker @"picker"
#define kMinAllowedZoom 1
#define kMaxAllowedZoom 22
#define kZoomSection 1

@interface OADownloadMapViewController() <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate, OAMapRendererDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;



@end

@implementation OADownloadMapViewController
{
    OsmAndAppInstance _app;
    NSDictionary *_data;
    
    OAMapRendererView *_map;
    NSInteger _minZoom;
    NSInteger _maxZoom;
    
    NSArray<NSDictionary *> *_zoomArray;
    NSArray<NSString *> *_possibleZoomValues;
    NSIndexPath *_pickerIndexPath;
    
    
    OAMapViewController *_mapViewController;
    UIView *_headerView;
    CALayer *_horizontalLine;
}

-(CGFloat) getNavBarHeight
{
    return gpxItemNavBarHeight;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return YES;
}

-(BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL) disableScroll
{
    return NO;
}

- (CGFloat) contentHeight
{
    return self.isLandscape || OAUtilities.isIPad ? DeviceScreenHeight - self.delegate.getHeaderViewHeight - self.getNavBarHeight - OAUtilities.getStatusBarHeight : DeviceScreenHeight - self.getNavBarHeight - OAUtilities.getStatusBarHeight;
}


- (void) applyLocalization
{
    [self setTitle:OALocalizedString(@"download_map")];
}

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        _app = [OsmAndApp instance];
        self.view.backgroundColor = UIColor.yellowColor;
        NSLog(@"init");
    }
    return self;
}

- (void) viewDidLoad
{
//    [super viewDidLoad];
//    //_app = [OsmAndApp instance];
//    self.view.backgroundColor = UIColor.yellowColor;
//    self.tableView.dataSource = self;
//    self.tableView.delegate = self;
//    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
//    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
//
//    // to delete/change
//    _possibleZoomValues = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22"];
//    _minZoom = 8;
//    _maxZoom = 16;
    
    [super viewDidLoad];
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    
    self.titleView.text = @"DOWNLOAD MAP";
    
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _tableView.frame.size.width, 100.0)];
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:_headerView.bounds];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.font = [UIFont systemFontOfSize:19.0];
    headerLabel.text = OALocalizedString(@"no_statistics");
    headerLabel.textColor = [UIColor lightGrayColor];
    headerLabel.numberOfLines = 3;
    [_headerView addSubview:headerLabel];
    [_tableView setTableHeaderView:_headerView];
    
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.estimatedRowHeight = kEstimatedRowHeight;

    //[self updateEditingMode:NO animated:NO];

    //[self.segmentView setSelectedSegmentIndex:_segmentType];
    //[self applySegmentType];
    //[self resetSortModeIfNeeded];
    //[self addBadge];

    
    //self.editToolbarView.hidden = YES;
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    //self.editToolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    //self.editToolbarView.layer addSublayer:_horizontalLine];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, 0.5);
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupView];
    [self.tableView reloadData];
}

//- (UIView *) getTopView
//{
//    return _navBarView;
//}
//
//- (UIView *) getMiddleView
//{
//    return _tableView;
//}
//
//- (void) adjustViews
//{
//    CGRect buttonFrame = _backButton.frame;
//    CGRect titleFrame = _titleView.frame;
//    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
//    buttonFrame.origin.y = statusBarHeight;
//    titleFrame.origin.y = statusBarHeight;
//    _backButton.frame = buttonFrame;
//    _titleView.frame = titleFrame;
//}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSMutableArray *mapTypeArr = [NSMutableArray array];
    NSMutableArray *zoomLevelArr = [NSMutableArray array];
    NSMutableArray *generalInfoArr = [NSMutableArray array];
    
    NSString *mapSourceName;
    if ([_app.data.lastMapSource.name isEqualToString:@"sqlitedb"])
        mapSourceName = [[_app.data.lastMapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    else
        mapSourceName = _app.data.lastMapSource.name;
    
    [mapTypeArr addObject:@{
        @"type" : @"OASettingsTableViewCell",
        @"title" : OALocalizedString(@"map_settings_type"),
        @"value" : mapSourceName,
    }];
    
    [zoomLevelArr addObject:@{
        @"type" : @"OAPreviewZoomLevelsCell",
        @"value" : OALocalizedString(@"preview_of_selected_zoom_levels"),
    }];
    
    [zoomLevelArr addObject:@{
        @"title" : OALocalizedString(@"rec_interval_minimum"),
        @"value" : [NSString stringWithFormat:@"%ld", _minZoom], // change?
        @"type"  : kCellTypeZoom,
    }];
    [zoomLevelArr addObject:@{
        @"title" : OALocalizedString(@"shared_string_maximum"),
        @"value" : [NSString stringWithFormat:@"%ld", _maxZoom], // change?
        @"type" : kCellTypeZoom,
    }];
    [zoomLevelArr addObject:@{
        @"type" : kCellTypePicker,
    }];
    
    [generalInfoArr addObject:@{
        @"type" : kCellTypeZoom,
        @"title" : OALocalizedString(@"number_of_tiles"),
        @"value" : @"120 700", // change
    }];
    
    [generalInfoArr addObject:@{
        @"type" : kCellTypeZoom,
        @"title" : OALocalizedString(@"download_size"),
        @"value" : @"~ 1448 MB", // change
    }];
    [tableData addObject:mapTypeArr];
    [tableData addObject:zoomLevelArr];
    [tableData addObject:generalInfoArr];
    _data = @{
        @"tableData" : tableData,
    };
}

- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TableView

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data[@"tableData"] count];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kZoomSection)
    {
        if ([self pickerIsShown])
            return 4;
        return 3;
    }
    return [_data[@"tableData"][section] count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
 
    if ([item[@"type"] isEqualToString:@"OASettingsTableViewCell"])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OAPreviewZoomLevelsCell"])
    {
        static NSString* const identifierCell = @"OAPreviewZoomLevelsCell";
        OAPreviewZoomLevelsCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPreviewZoomLevelsCell" owner:self options:nil];
            cell = (OAPreviewZoomLevelsCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.descriptionLabel.text = item[@"value"];
            cell.minLevelZoomView.backgroundColor = UIColor.grayColor;
            cell.minZoomPropertyLabel.text = [NSString stringWithFormat:@"%ld",_minZoom];
            
            cell.maxLevelZoomView.backgroundColor = UIColor.grayColor;
            cell.maxZoomPropertyLabel.text = [NSString stringWithFormat:@"%ld",_maxZoom];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeZoom])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        
        cell.lbTime.textColor = [UIColor blackColor];
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypePicker])
    {
        static NSString* const identifierCell = @"OACustomPickerTableViewCell";
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACustomPickerCell" owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        NSInteger minZoom = _minZoom >= kMinAllowedZoom && _minZoom <= kMaxAllowedZoom ? _minZoom : 1;
        NSInteger maxZoom = _maxZoom >= kMinAllowedZoom && _maxZoom <= kMaxAllowedZoom ? _maxZoom : 1;
        [cell.picker selectRow:indexPath.row == 1 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0.01;
    }
    else if (section == 1)
    {
        NSString *title = OALocalizedString(@"res_zoom_levels");
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
    }
    else
    {
        return 8.0;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        NSString *title = OALocalizedString(@"res_zoom_levels");
        OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
        if (!title)
        {
            vw.label.text = title;
            return vw;
        }
        vw.label.text = [title upperCase];
        return vw;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 1)
    {
        NSString *title = @"The detalization level increases the downloading size of map"; // change
        return [OATableViewCustomFooterView getHeight:title width:tableView.bounds.size.width];
    }
    return 0.01;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 1)
    {
        NSString *title = @"The detalization level increases the downloading size of map"; // change
        OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kFooterId];
        vw.label.text = title;
        return vw;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:_pickerIndexPath])
        return 162.0;
    return UITableViewAutomaticDimension;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
    if (indexPath.section == kZoomSection && [item[@"type"] isEqualToString:kCellTypeZoom])
    {
        [self.tableView beginUpdates];

        if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self pickerIsShown])
                [self hideExistingPicker];

            [self showNewPickerAtIndex:newPickerIndexPath];
            _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    if (indexPath.section == 0)
    {
        OASelectMapSourceViewController *mapSource = [[OASelectMapSourceViewController alloc] init];
        [self presentViewController:mapSource animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Picker

- (BOOL) pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void) hideExistingPicker
{
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (void) hidePicker
{
    [self.tableView beginUpdates];
    if ([self pickerIsShown])
        [self hideExistingPicker];
    [self.tableView endUpdates];
}

- (NSIndexPath *) calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath
{
    NSIndexPath *newIndexPath;
    if (([self pickerIsShown]) && (_pickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:kZoomSection];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:kZoomSection];
    
    return newIndexPath;
}

- (void) showNewPickerAtIndex:(NSIndexPath *)indexPath
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kZoomSection]];
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[@"tableData"][indexPath.section][indexPath.row];
    if (indexPath.section == kZoomSection && [item[@"type"] isEqualToString:kCellTypeZoom])
    {
        NSArray *ar = _data[@"tableData"][indexPath.section];
        if ([self pickerIsShown])
        {
            if ([indexPath isEqual:_pickerIndexPath])
                return ar[3];
            else if (indexPath.row == 1)
                return ar[1];
            else
                return ar[2];
        }
        else
        {
            if (indexPath.row == 1)
                return ar[1];
            else if (indexPath.row == 2)
                return ar[2];
        }
    }
    return _data[@"tableData"][indexPath.section][indexPath.row];
}

- (void)zoomChanged:(NSString *)zoom tag: (NSInteger)pickerTag
{
    if (pickerTag == 2)
        _minZoom = [zoom intValue];
    else if (pickerTag == 3)
        _maxZoom = [zoom intValue];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section], [NSIndexPath indexPathForRow:0 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}


- (void)frameRendered {
    return;
}


@end
